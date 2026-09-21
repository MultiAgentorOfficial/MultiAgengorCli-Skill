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

[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || { echo "This bootstrap supports Apple Silicon macOS only." >&2; exit 1; }
json_escape() { local v="${1:-}"; v="${v//\\/\\\\}"; v="${v//\"/\\\"}"; printf '%s' "$v"; }
launcher="$install_root/multiagentor"
if [[ $check_only -eq 1 ]]; then
  installed=false; [[ -x "$launcher" ]] && installed=true
  printf '{"mode":"check-only","platform":"darwin-arm64","installed":%s,"invocation":"%s","packageName":"%s","registry":"%s","installRoot":"%s"}\n' "$installed" "$(json_escape "$launcher")" "$package_name" "$registry" "$(json_escape "$install_root")"
  exit 0
fi

mkdir -p "$install_root"
work="$(mktemp -d "$install_root/.bootstrap.XXXXXX")"
trap 'rm -rf "$work"' EXIT
cache_key="$(date +%s)"
curl -fsSL --retry 3 -H 'User-Agent: multiagentor-skill-bootstrap' -H 'Cache-Control: no-cache, no-store' -H 'Pragma: no-cache' -o "$work/latest.json" "$registry/$package_name/latest?cache=$cache_key"
latest="$(tr -d '\n' < "$work/latest.json" | sed -nE 's/.*"version":"([^"]+)".*/\1/p')"
engine="$(tr -d '\n' < "$work/latest.json" | sed -nE 's/.*"engines":\{"node":"([^"]+)"\}.*/\1/p')"
integrity="$(tr -d '\n' < "$work/latest.json" | sed -nE 's/.*"integrity":"([^"]+)".*/\1/p')"
[[ -n "$latest" ]] || { echo "npm package has no latest release: $package_name" >&2; exit 1; }
[[ "$engine" =~ \>=[[:space:]]*([0-9]+) ]] || { echo "Unsupported Node engine: $engine" >&2; exit 1; }
node_major="${BASH_REMATCH[1]}"

node_version="$(curl -fsSL https://nodejs.org/dist/index.json | sed 's/},{/}\n{/g' | grep '"lts":"' | grep 'osx-arm64-tar' | sed -nE 's/.*"version":"(v'"$node_major"'\.[^"]+)".*/\1/p' | head -n 1)"
[[ -n "$node_version" ]] || { echo "No compatible Node LTS osx-arm64 release found." >&2; exit 1; }
archive_name="node-$node_version-darwin-arm64.tar.gz"
node_root="$install_root/runtime/$node_version"
node_bin="$node_root/bin/node"
if [[ ! -x "$node_bin" ]]; then
  curl -fL --retry 3 -o "$work/$archive_name" "https://nodejs.org/dist/$node_version/$archive_name"
  curl -fL --retry 3 -o "$work/SHASUMS256.txt" "https://nodejs.org/dist/$node_version/SHASUMS256.txt"
  expected="$(awk -v n="$archive_name" '$2==n {print $1}' "$work/SHASUMS256.txt")"
  actual="$(shasum -a 256 "$work/$archive_name" | awk '{print $1}')"
  [[ -n "$expected" && "$actual" == "$expected" ]] || { echo "Node archive checksum mismatch." >&2; exit 1; }
  mkdir -p "$install_root/runtime"
  tar -xzf "$work/$archive_name" -C "$work"
  mv "$work/node-$node_version-darwin-arm64" "$node_root"
fi

export PATH="$node_root/bin:$PATH"
stage="$work/package"
mkdir -p "$stage"
npm install --global --prefix "$stage" "$package_name@$latest" --registry "$registry" --no-audit --no-fund
package_root="$stage/lib/node_modules/$package_name"
package_file="$package_root/package.json"
[[ -f "$package_file" ]] || { echo "Installed npm package lacks package.json." >&2; exit 1; }
entry_rel="$(node -p 'const p=require(process.argv[1]); typeof p.bin==="string"?p.bin:(p.bin.multiagentor||Object.values(p.bin)[0])' "$package_file")"
entry="$package_root/$entry_rel"
[[ -f "$entry" ]] || { echo "Installed npm package lacks its CLI entrypoint." >&2; exit 1; }
cli_version="$(node "$entry" --version)"
node "$entry" --help >/dev/null

target="$install_root/package"
rollback=""
if [[ -e "$target" ]]; then rollback="$install_root/.package-rollback.$$.$RANDOM"; mv "$target" "$rollback"; fi
if mv "$stage" "$target"; then
  stable_entry="$target/lib/node_modules/$package_name/$entry_rel"
  cat > "$launcher" <<EOF
#!/usr/bin/env bash
exec "$node_bin" "$stable_entry" "\$@"
EOF
  chmod 0755 "$launcher"
  "$launcher" --help >/dev/null
  [[ -z "$rollback" ]] || rm -rf "$rollback"
else
  rm -rf "$target"
  [[ -z "$rollback" ]] || mv "$rollback" "$target"
  echo "npm package replacement failed and was rolled back." >&2
  exit 1
fi

printf '{"mode":"installed","platform":"darwin-arm64","invocation":"%s","cliVersion":"%s","nodeVersion":"%s","npmVersion":"%s","nodeEngine":"%s","packageName":"%s","registry":"%s","integrity":"%s","installRoot":"%s"}\n' \
  "$(json_escape "$launcher")" "$(json_escape "$cli_version")" "$(json_escape "$node_version")" "$(npm --version)" "$(json_escape "$engine")" "$package_name" "$(json_escape "$registry")" "$(json_escape "$integrity")" "$(json_escape "$install_root")"
