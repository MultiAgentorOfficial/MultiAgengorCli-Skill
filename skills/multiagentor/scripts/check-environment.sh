#!/usr/bin/env bash
set -u

cli_repo=""
cli_path=""
check_remote=0
skill_root="$(cd "$(dirname "$0")/.." && pwd)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli-repo) cli_repo="$2"; shift 2 ;;
    --cli-path) cli_path="$2"; shift 2 ;;
    --check-remote) check_remote=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

command_path() { command -v "$1" 2>/dev/null || true; }
json_string() {
  if [[ -z "${1:-}" ]]; then printf 'null'; return; fi
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\t'/\\t}"
  printf '"%s"' "$value"
}

node_path="$(command_path node)"
node_version=""
[[ -n "$node_path" ]] && node_version="$("$node_path" --version 2>/dev/null || true)"
nvm_path="$(command_path nvm)"

if [[ -z "$cli_path" && -n "${MULTIAGENTOR_CLI_PATH:-}" ]]; then cli_path="$MULTIAGENTOR_CLI_PATH"; fi
if [[ -z "$cli_path" ]]; then cli_path="$(command_path multiagentor)"; fi
if [[ -z "$cli_path" && -n "$cli_repo" && -f "$cli_repo/dist/bin/multiagentor.js" ]]; then cli_path="$cli_repo/dist/bin/multiagentor.js"; fi

cli_version=""
cli_help=false
if [[ -n "$cli_path" ]]; then
  if [[ "$cli_path" == *.js && -n "$node_path" ]]; then
    cli_version="$("$node_path" "$cli_path" --version 2>/dev/null || true)"
    "$node_path" "$cli_path" --help >/dev/null 2>&1 && cli_help=true
  elif [[ -x "$cli_path" ]]; then
    cli_version="$("$cli_path" --version 2>/dev/null || true)"
    "$cli_path" --help >/dev/null 2>&1 && cli_help=true
  fi
fi

package_version=""; node_engine=""; package_manager=""; repo_head=""; repo_remote=""; remote_head=""
if [[ -n "$cli_repo" && -f "$cli_repo/package.json" && -n "$node_path" ]]; then
  package_version="$("$node_path" -p 'require(process.argv[1]).version' "$cli_repo/package.json")"
  node_engine="$("$node_path" -p 'require(process.argv[1]).engines?.node || ""' "$cli_repo/package.json")"
  package_manager="$("$node_path" -p 'require(process.argv[1]).packageManager || ""' "$cli_repo/package.json")"
fi
if [[ -n "$cli_repo" && -d "$cli_repo/.git" ]] && command -v git >/dev/null 2>&1; then
  repo_head="$(git -C "$cli_repo" rev-parse HEAD 2>/dev/null || true)"
  repo_remote="$(git -C "$cli_repo" remote get-url origin 2>/dev/null || true)"
  if [[ $check_remote -eq 1 && -n "$repo_remote" ]]; then
    remote_head="$(git ls-remote "$repo_remote" HEAD 2>/dev/null | awk '{print $1}')"
  fi
fi

skill_version=""; skill_repo_head=""; skill_repo_remote=""; skill_remote_head=""; skill_dirty="null"
if [[ -f "$skill_root/SKILL.md" ]]; then
  skill_version="$(sed -nE "s/^  version:[[:space:]]*['\"]?([^'\"]+)['\"]?[[:space:]]*$/\1/p" "$skill_root/SKILL.md" | head -n 1)"
fi
if command -v git >/dev/null 2>&1 && skill_top="$(git -C "$skill_root" rev-parse --show-toplevel 2>/dev/null)"; then
  skill_repo_head="$(git -C "$skill_top" rev-parse HEAD 2>/dev/null || true)"
  [[ "$skill_repo_head" =~ ^[0-9a-f]{40}$ ]] || skill_repo_head=""
  skill_repo_remote="$(git -C "$skill_top" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$(git -C "$skill_top" status --porcelain 2>/dev/null)" ]]; then skill_dirty=true; else skill_dirty=false; fi
  if [[ $check_remote -eq 1 && -n "$skill_repo_remote" ]]; then
    skill_remote_head="$(git ls-remote "$skill_repo_remote" HEAD 2>/dev/null | awk '{print $1}')"
  fi
fi

cat <<JSON
{
  "skillVersion": $(json_string "$skill_version"),
  "skillRoot": $(json_string "$skill_root"),
  "skillRepoHead": $(json_string "$skill_repo_head"),
  "skillRepoRemote": $(json_string "$skill_repo_remote"),
  "skillRemoteHead": $(json_string "$skill_remote_head"),
  "skillDirty": $skill_dirty,
  "os": $(json_string "$(uname -s 2>/dev/null || true)"),
  "architecture": $(json_string "$(uname -m 2>/dev/null || true)"),
  "nodePath": $(json_string "$node_path"),
  "nodeVersion": $(json_string "$node_version"),
  "nvmPath": $(json_string "$nvm_path"),
  "cliPath": $(json_string "$cli_path"),
  "cliVersion": $(json_string "$cli_version"),
  "cliHelpAvailable": $cli_help,
  "cliRepo": $(json_string "$cli_repo"),
  "packageVersion": $(json_string "$package_version"),
  "nodeEngine": $(json_string "$node_engine"),
  "packageManager": $(json_string "$package_manager"),
  "repoHead": $(json_string "$repo_head"),
  "repoRemote": $(json_string "$repo_remote"),
  "remoteHead": $(json_string "$remote_head"),
  "dataDir": $(json_string "${MULTIAGENTOR_DATA_DIR:-}"),
  "apiUrl": $(json_string "${MULTIAGENTOR_API_URL:-}"),
  "browserExecutable": $(json_string "${MULTIAGENTOR_BROWSER_EXECUTABLE:-}")
}
JSON
