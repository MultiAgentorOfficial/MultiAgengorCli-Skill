#!/usr/bin/env bash
set -euo pipefail

cli_path="${MULTIAGENTOR_CLI_PATH:-}"
timeout_seconds=15
probe=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli-path) cli_path="$2"; shift 2 ;;
    --ready-timeout) timeout_seconds="$2"; shift 2 ;;
    --probe) probe=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ "$timeout_seconds" =~ ^[0-9]+$ && $timeout_seconds -ge 5 && $timeout_seconds -le 60 ]] || { echo 'ready timeout must be 5-60 seconds' >&2; exit 2; }
if [[ -z "$cli_path" ]]; then cli_path="$(command -v multiagentor 2>/dev/null || true)"; fi
if [[ -z "$cli_path" ]]; then
  managed="$HOME/Library/Application Support/multiagentor-scenario-cli/portable/multiagentor"
  [[ -x "$managed" ]] && cli_path="$managed"
fi
[[ -x "$cli_path" ]] || { echo 'A usable MultiAgentor CLI launcher was not found.' >&2; exit 1; }

base="$HOME/.multiagentor-auth"
session="$base/$(date +%s).$$.$RANDOM"
mkdir -p "$session"
chmod 700 "$base" "$session"
worker="$(cd "$(dirname "$0")" && pwd)/auth-login-window.sh"
command_file="$session/login.command"
printf '#!/usr/bin/env bash\nexec bash %q --cli-path %q --session-directory %q' "$worker" "$cli_path" "$session" > "$command_file"
[[ $probe -eq 1 ]] && printf ' --probe' >> "$command_file"
printf '\n' >> "$command_file"
chmod 700 "$command_file"

if ! open -a Terminal "$command_file"; then
  printf '{"started":false,"ready":false,"fallbackScript":"%s","sessionDirectory":"%s"}\n' "$command_file" "$session"
  exit 1
fi

ready="$session/ready"
for ((i=0; i<timeout_seconds*4; i++)); do
  [[ -f "$ready" ]] && break
  sleep 0.25
done
is_ready=false; [[ -f "$ready" ]] && is_ready=true
if [[ "$is_ready" == false ]]; then open "$session" >/dev/null 2>&1 || true; fi
printf '{"started":true,"ready":%s,"readyMarker":"%s","resultFile":"%s","fallbackScript":"%s","sessionDirectory":"%s","probe":%s}\n' "$is_ready" "$ready" "$session/result.json" "$command_file" "$session" "$([[ $probe -eq 1 ]] && echo true || echo false)"
[[ "$is_ready" == true ]]
