#!/usr/bin/env bash
set -u

cli_path=""
package_name="multiagentor-scenario-cli"
registry="https://registry.npmjs.org"
check_remote=0
skill_root="$(cd "$(dirname "$0")/.." && pwd)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli-path) cli_path="$2"; shift 2 ;;
    --package-name) package_name="$2"; shift 2 ;;
    --registry) registry="${2%/}"; shift 2 ;;
    --check-remote) check_remote=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

command_path() { command -v "$1" 2>/dev/null || true; }
json_string() { if [[ -z "${1:-}" ]]; then printf 'null'; return; fi; local v="$1"; v="${v//\\/\\\\}"; v="${v//\"/\\\"}"; v="${v//$'\n'/\\n}"; printf '"%s"' "$v"; }
node_path="$(command_path node)"; node_version=""; [[ -n "$node_path" ]] && node_version="$(node --version 2>/dev/null || true)"
npm_path="$(command_path npm)"; npm_version=""; [[ -n "$npm_path" ]] && npm_version="$(npm --version 2>/dev/null || true)"
nvm_path="$(command_path nvm)"
[[ -z "$cli_path" && -n "${MULTIAGENTOR_CLI_PATH:-}" ]] && cli_path="$MULTIAGENTOR_CLI_PATH"
[[ -z "$cli_path" ]] && cli_path="$(command_path multiagentor)"
cli_version=""; cli_help=false
if [[ -n "$cli_path" ]]; then cli_version="$($cli_path --version 2>/dev/null || true)"; $cli_path --help >/dev/null 2>&1 && cli_help=true; fi
system_version="$(sw_vers -productVersion 2>/dev/null || true)"
chrome_path="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
chrome_version=""; chrome_major=""
if [[ -x "$chrome_path" ]]; then
  chrome_version="$($chrome_path --version 2>/dev/null | sed -nE 's/.* ([0-9]+(\.[0-9]+)+).*/\1/p')"
  chrome_major="${chrome_version%%.*}"
else chrome_path=""; fi
managed_browser_version=""; managed_browser_major=""
if [[ -n "${MULTIAGENTOR_BROWSER_EXECUTABLE:-}" && -x "${MULTIAGENTOR_BROWSER_EXECUTABLE}" ]]; then
  managed_browser_version="$("${MULTIAGENTOR_BROWSER_EXECUTABLE}" --version 2>/dev/null | sed -nE 's/.* ([0-9]+(\.[0-9]+)+).*/\1/p' | head -n 1 || true)"
  managed_browser_major="${managed_browser_version%%.*}"
fi
latest=""; engine=""; integrity=""
if [[ $check_remote -eq 1 ]]; then
  work="$(mktemp)"; trap 'rm -f "$work"' EXIT
  cache_key="$(date +%s)"
  curl -fsSL --retry 3 -H 'Cache-Control: no-cache, no-store' -H 'Pragma: no-cache' -o "$work" "$registry/$package_name/latest?cache=$cache_key"
  latest="$(tr -d '\n' < "$work" | sed -nE 's/.*"version":"([^"]+)".*/\1/p')"
  engine="$(tr -d '\n' < "$work" | sed -nE 's/.*"engines":\{"node":"([^"]+)"\}.*/\1/p')"
  integrity="$(tr -d '\n' < "$work" | sed -nE 's/.*"integrity":"([^"]+)".*/\1/p')"
fi
skill_version="$(sed -nE "s/^  version:[[:space:]]*['\"]?([^'\"]+)['\"]?[[:space:]]*$/\1/p" "$skill_root/SKILL.md" | head -n 1)"
cat <<JSON
{"skillVersion":$(json_string "$skill_version"),"skillRoot":$(json_string "$skill_root"),"os":$(json_string "$(uname -s)"),"architecture":$(json_string "$(uname -m)"),"systemVersion":$(json_string "$system_version"),"chromePath":$(json_string "$chrome_path"),"chromeVersion":$(json_string "$chrome_version"),"chromeMajor":$(json_string "$chrome_major"),"managedBrowserVersion":$(json_string "$managed_browser_version"),"managedBrowserMajor":$(json_string "$managed_browser_major"),"nodePath":$(json_string "$node_path"),"nodeVersion":$(json_string "$node_version"),"npmPath":$(json_string "$npm_path"),"npmVersion":$(json_string "$npm_version"),"nvmPath":$(json_string "$nvm_path"),"cliPath":$(json_string "$cli_path"),"cliVersion":$(json_string "$cli_version"),"cliHelpAvailable":$cli_help,"packageName":$(json_string "$package_name"),"registry":$(json_string "$registry"),"latestVersion":$(json_string "$latest"),"nodeEngine":$(json_string "$engine"),"integrity":$(json_string "$integrity"),"dataDir":$(json_string "${MULTIAGENTOR_DATA_DIR:-}"),"apiUrl":$(json_string "${MULTIAGENTOR_API_URL:-}"),"browserExecutable":$(json_string "${MULTIAGENTOR_BROWSER_EXECUTABLE:-}")}
JSON
