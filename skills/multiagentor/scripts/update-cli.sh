#!/usr/bin/env bash
set -euo pipefail

repository="https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli.git"
ref="master"
install_root="${HOME}/Library/Application Support/multiagentor-scenario-cli/portable"
check_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repository) repository="$2"; shift 2 ;;
    --ref) ref="$2"; shift 2 ;;
    --install-root) install_root="$2"; shift 2 ;;
    --check-only) check_only=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

json_escape() { local v="${1:-}"; v="${v//\\/\\\\}"; v="${v//\"/\\\"}"; printf '%s' "$v"; }
launcher="$install_root/multiagentor"
source_root="$install_root/source"
previous_version=""
[[ -x "$launcher" ]] && previous_version="$($launcher --version 2>/dev/null | head -n 1 || true)"
local_commit=""
remote_commit=""
source_mode="missing"

if command -v git >/dev/null 2>&1 && [[ -d "$source_root/.git" ]]; then
  source_mode="git"
  local_commit="$(git -C "$source_root" rev-parse HEAD)"
  remote_commit="$(git ls-remote "$repository" "refs/heads/$ref" | awk 'NR==1{print $1}')"
  [[ "$local_commit" =~ ^[0-9a-f]{40}$ && "$remote_commit" =~ ^[0-9a-f]{40}$ ]] || { echo "Cannot compare CLI source commits." >&2; exit 1; }
elif [[ -f "$source_root/package.json" ]]; then
  source_mode="archive"
fi

needs_update=false
[[ -n "$previous_version" && "$source_mode" == git && "$local_commit" == "$remote_commit" ]] || needs_update=true
if [[ "$needs_update" == false ]] && ! "$launcher" --help >/dev/null 2>&1; then needs_update=true; fi

if [[ $check_only -eq 1 || "$needs_update" == false ]]; then
  mode="current"; [[ $check_only -eq 1 ]] && mode="check-only"
  invocation=""; [[ -x "$launcher" ]] && invocation="$launcher"
  printf '{"mode":"%s","updateAvailable":%s,"updated":false,"invocation":"%s","cliVersion":"%s","localCommit":"%s","remoteCommit":"%s","sourceMode":"%s","repository":"%s","ref":"%s"}\n' \
    "$mode" "$needs_update" "$(json_escape "$invocation")" "$(json_escape "$previous_version")" "$local_commit" "$remote_commit" "$source_mode" "$(json_escape "$repository")" "$(json_escape "$ref")"
  exit 0
fi

bootstrap="$(cd "$(dirname "$0")" && pwd)/bootstrap-portable-cli.sh"
output="$(bash "$bootstrap" --repository "$repository" --ref "$ref" --install-root "$install_root")"
json_line="$(printf '%s\n' "$output" | awk '/^\{/{line=$0} END{print line}')"
[[ -n "$json_line" ]] || { echo "CLI bootstrap/update did not return JSON." >&2; exit 1; }
cli_version="$(printf '%s' "$json_line" | sed -nE 's/.*"cliVersion":"([^"]*)".*/\1/p')"
invocation="$(printf '%s' "$json_line" | sed -nE 's/.*"invocation":"([^"]*)".*/\1/p')"
installed_commit="$(printf '%s' "$json_line" | sed -nE 's/.*"sourceCommit":"([^"]*)".*/\1/p')"
node_version="$(printf '%s' "$json_line" | sed -nE 's/.*"nodeVersion":"([^"]*)".*/\1/p')"
pnpm_version="$(printf '%s' "$json_line" | sed -nE 's/.*"pnpmVersion":"([^"]*)".*/\1/p')"
[[ -n "$installed_commit" ]] && source_mode="git" || source_mode="archive"
printf '{"mode":"updated","updateAvailable":true,"updated":true,"previousVersion":"%s","cliVersion":"%s","invocation":"%s","localCommit":"%s","remoteCommit":"%s","sourceMode":"%s","nodeVersion":"%s","pnpmVersion":"%s","repository":"%s","ref":"%s"}\n' \
  "$(json_escape "$previous_version")" "$(json_escape "$cli_version")" "$(json_escape "$invocation")" "$local_commit" "${installed_commit:-$remote_commit}" "$source_mode" "$node_version" "$pnpm_version" "$(json_escape "$repository")" "$(json_escape "$ref")"
