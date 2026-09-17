#!/usr/bin/env bash
set -euo pipefail

package_name="multiagentor-scenario-cli"
registry="https://registry.npmjs.org"
install_root="${HOME}/Library/Application Support/multiagentor-scenario-cli/portable"
check_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --package-name) package_name="$2"; shift 2 ;;
    --registry) registry="${2%/}"; shift 2 ;;
    --install-root) install_root="$2"; shift 2 ;;
    --check-only) check_only=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

json_escape() { local v="${1:-}"; v="${v//\\/\\\\}"; v="${v//\"/\\\"}"; printf '%s' "$v"; }
launcher="$install_root/multiagentor"
work="$(mktemp -d "${TMPDIR:-/tmp}/multiagentor-update.XXXXXX")"
trap 'rm -rf "$work"' EXIT
curl -fsSL --retry 3 -H 'User-Agent: multiagentor-skill-updater' -o "$work/latest.json" "$registry/$package_name/latest"
latest="$(tr -d '\n' < "$work/latest.json" | sed -nE 's/.*"version":"([^"]+)".*/\1/p')"
engine="$(tr -d '\n' < "$work/latest.json" | sed -nE 's/.*"engines":\{"node":"([^"]+)"\}.*/\1/p')"
integrity="$(tr -d '\n' < "$work/latest.json" | sed -nE 's/.*"integrity":"([^"]+)".*/\1/p')"
[[ -n "$latest" ]] || { echo "npm package has no latest release: $package_name" >&2; exit 1; }
current=""
[[ -x "$launcher" ]] && current="$($launcher --version 2>/dev/null | head -n 1 || true)"
needs_update=false
[[ -n "$current" && "$current" == "$latest" ]] || needs_update=true
if [[ "$needs_update" == false ]] && ! "$launcher" --help >/dev/null 2>&1; then needs_update=true; fi

if [[ $check_only -eq 1 || "$needs_update" == false ]]; then
  mode="current"; [[ $check_only -eq 1 ]] && mode="check-only"
  invocation=""; [[ -x "$launcher" ]] && invocation="$launcher"
  printf '{"mode":"%s","updateAvailable":%s,"updated":false,"invocation":"%s","cliVersion":"%s","latestVersion":"%s","nodeEngine":"%s","packageName":"%s","registry":"%s","integrity":"%s"}\n' \
    "$mode" "$needs_update" "$(json_escape "$invocation")" "$(json_escape "$current")" "$latest" "$(json_escape "$engine")" "$package_name" "$(json_escape "$registry")" "$(json_escape "$integrity")"
  exit 0
fi

bootstrap="$(cd "$(dirname "$0")" && pwd)/bootstrap-portable-cli.sh"
output="$(bash "$bootstrap" --package-name "$package_name" --registry "$registry" --install-root "$install_root")"
json_line="$(printf '%s\n' "$output" | awk '/^\{/{line=$0} END{print line}')"
[[ -n "$json_line" ]] || { echo "CLI bootstrap did not return JSON." >&2; exit 1; }
cli_version="$(printf '%s' "$json_line" | sed -nE 's/.*"cliVersion":"([^"]*)".*/\1/p')"
invocation="$(printf '%s' "$json_line" | sed -nE 's/.*"invocation":"([^"]*)".*/\1/p')"
node_version="$(printf '%s' "$json_line" | sed -nE 's/.*"nodeVersion":"([^"]*)".*/\1/p')"
npm_version="$(printf '%s' "$json_line" | sed -nE 's/.*"npmVersion":"([^"]*)".*/\1/p')"
printf '{"mode":"updated","updateAvailable":true,"updated":true,"previousVersion":"%s","cliVersion":"%s","latestVersion":"%s","invocation":"%s","nodeVersion":"%s","npmVersion":"%s","nodeEngine":"%s","packageName":"%s","registry":"%s","integrity":"%s"}\n' \
  "$(json_escape "$current")" "$(json_escape "$cli_version")" "$latest" "$(json_escape "$invocation")" "$node_version" "$npm_version" "$(json_escape "$engine")" "$package_name" "$(json_escape "$registry")" "$(json_escape "$integrity")"
