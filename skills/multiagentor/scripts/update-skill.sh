#!/usr/bin/env bash
set -euo pipefail

repository="MultiAgentorOfficial/MultiAgengorCli-Skill"
ref="main"
check_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repository) repository="$2"; shift 2 ;;
    --ref) ref="$2"; shift 2 ;;
    --check-only) check_only=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

skill_root="$(cd "$(dirname "$0")/.." && pwd)"
read_version() { sed -nE "s/^  version:[[:space:]]*['\"]?([^'\"]+)['\"]?[[:space:]]*$/\1/p" "$1" | head -n 1; }
valid_version() { [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; }
version_gt() { awk -v a="$1" -v b="$2" 'BEGIN{split(a,x,".");split(b,y,".");for(i=1;i<=3;i++){if(x[i]+0>y[i]+0)exit 0;if(x[i]+0<y[i]+0)exit 1}exit 1}'; }
integrity() {
  local root="$1" f
  for f in SKILL.md agents/openai.yaml references/installation.md references/dynamic-discovery.md references/execution-workflow.md references/supervised-execution.md references/troubleshooting.md scripts/update-skill.ps1 scripts/update-skill.sh scripts/update-cli.ps1 scripts/update-cli.sh scripts/bootstrap-portable-cli.ps1 scripts/bootstrap-portable-cli.sh scripts/check-environment.ps1 scripts/check-environment.sh; do
    [[ -f "$root/$f" ]] || return 1
  done
  grep -q '^name:[[:space:]]*multiagentor[[:space:]]*$' "$root/SKILL.md"
}
emit() { printf '{"currentVersion":"%s","latestVersion":"%s","updated":%s,"integrityOk":%s,"mode":"%s","restartRequired":%s}\n' "$1" "$2" "$3" "$4" "$5" "$3"; }

current="$(read_version "$skill_root/SKILL.md")"; valid_version "$current" || { echo 'Invalid local Skill version.' >&2; exit 1; }
local_ok=true; integrity "$skill_root" || local_ok=false
work="$(mktemp -d "$(dirname "$skill_root")/.multiagentor-update.XXXXXX")"
trap 'rm -rf "$work"' EXIT
cache_key="$(date +%s)"
curl -fL --retry 3 -H 'Cache-Control: no-cache' -o "$work/remote-SKILL.md" "https://raw.githubusercontent.com/$repository/$ref/skills/multiagentor/SKILL.md?cache=$cache_key"
latest="$(read_version "$work/remote-SKILL.md")"; valid_version "$latest" || { echo 'Invalid remote Skill version.' >&2; exit 1; }

needs=false
version_gt "$latest" "$current" && needs=true
[[ "$local_ok" == true ]] || needs=true
if [[ "$needs" == false ]]; then emit "$current" "$latest" false true current; exit 0; fi
if [[ $check_only -eq 1 ]]; then emit "$current" "$latest" false "$local_ok" available-or-repair; exit 0; fi

curl -fL --retry 3 -H 'Cache-Control: no-cache' -o "$work/repository.zip" "https://github.com/$repository/archive/refs/heads/$ref.zip?cache=$cache_key"
mkdir -p "$work/extract"
ditto -x -k "$work/repository.zip" "$work/extract"
source_root="$(find "$work/extract" -path '*/skills/multiagentor/SKILL.md' -print | head -n 1 | sed 's#/SKILL.md$##')"
[[ -n "$source_root" ]] || { echo 'Official archive lacks skills/multiagentor.' >&2; exit 1; }
staged_version="$(read_version "$source_root/SKILL.md")"
[[ "$staged_version" == "$latest" ]] && integrity "$source_root" || { echo 'Staged Skill validation failed.' >&2; exit 1; }

parent="$(dirname "$skill_root")"; id="$$.$RANDOM"
staged="$parent/.multiagentor-staged.$id"; rollback="$parent/.multiagentor-rollback.$id"
cp -R "$source_root" "$staged"
mv "$skill_root" "$rollback"
if mv "$staged" "$skill_root" && [[ "$(read_version "$skill_root/SKILL.md")" == "$latest" ]] && integrity "$skill_root"; then
  rm -rf "$rollback"
  emit "$current" "$latest" true true archive-replace
else
  rm -rf "$skill_root"
  mv "$rollback" "$skill_root"
  echo 'Skill replacement failed and was rolled back.' >&2
  exit 1
fi
