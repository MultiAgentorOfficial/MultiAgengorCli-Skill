#!/usr/bin/env bash
set -u

cli_path=""
session_directory=""
probe=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli-path) cli_path="$2"; shift 2 ;;
    --session-directory) session_directory="$2"; shift 2 ;;
    --probe) probe=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -x "$cli_path" && -n "$session_directory" ]] || { echo 'A usable CLI path and session directory are required.' >&2; exit 1; }
mkdir -p "$session_directory"
chmod 700 "$session_directory"
printf 'ready\n' > "$session_directory/ready"
chmod 600 "$session_directory/ready"

if [[ $probe -eq 1 ]]; then
  printf 'MultiAgentor login window probe is ready.\n'
  sleep 2
  exit 0
fi

authenticated=false
message=""
help_text="$($cli_path auth login --help 2>&1 || true)"
if ! grep -Eq '(^|[[:space:]])--password-stdin([[:space:]]|$)' <<<"$help_text"; then
  message='This CLI version does not support auth login --password-stdin. Update the npm package before secure login. Password arguments are disabled by this Skill.'
  printf 'Login failed: %s\n' "$message" >&2
else
  read -r -p 'MultiAgentor email: ' email
  read -r -s -p 'MultiAgentor password: ' password
  printf '\n'
  if printf '%s\n' "$password" | "$cli_path" auth login --email "$email" --password-stdin; then
    unset password
    status_text="$($cli_path auth status 2>&1 || true)"
    if grep -Eq '"authenticated"[[:space:]]*:[[:space:]]*true' <<<"$status_text"; then
      authenticated=true
      message='Authenticated successfully.'
      printf '%s\n' "$message"
    else
      message='Login command returned, but auth status did not report authenticated: true.'
      printf 'Login failed: %s\n' "$message" >&2
    fi
  else
    unset password
    message='CLI login command failed.'
    printf 'Login failed: %s\n' "$message" >&2
  fi
fi

escaped_message="${message//\\/\\\\}"; escaped_message="${escaped_message//\"/\\\"}"
printf '{"authenticated":%s,"message":"%s"}\n' "$authenticated" "$escaped_message" > "$session_directory/result.json"
chmod 600 "$session_directory/result.json"
read -r -p 'Press Enter to close this window'
[[ "$authenticated" == true ]]
