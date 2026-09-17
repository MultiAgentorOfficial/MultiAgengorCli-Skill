#!/usr/bin/env bash
set -euo pipefail

repository="https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli.git"
ref="master"
install_root="${HOME}/Library/Application Support/multiagentor-scenario-cli/portable"
source_directory=""
check_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repository) repository="$2"; shift 2 ;;
    --ref) ref="$2"; shift 2 ;;
    --install-root) install_root="$2"; shift 2 ;;
    --source-directory) source_directory="$2"; shift 2 ;;
    --check-only) check_only=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || { echo "This bootstrap supports Apple Silicon macOS only." >&2; exit 1; }
json_escape() { local v="$1"; v="${v//\\/\\\\}"; v="${v//\"/\\\"}"; printf '%s' "$v"; }
launcher="$install_root/multiagentor"
if [[ $check_only -eq 1 ]]; then
  installed=false; [[ -x "$launcher" ]] && installed=true
  printf '{"mode":"check-only","platform":"darwin-arm64","installed":%s,"invocation":"%s","repository":"%s","ref":"%s"}\n' "$installed" "$(json_escape "$launcher")" "$(json_escape "$repository")" "$(json_escape "$ref")"
  exit 0
fi

mkdir -p "$install_root"
work="$(mktemp -d "$install_root/.bootstrap.XXXXXX")"
trap 'rm -rf "$work"' EXIT
source_root=""
source_commit=""
if [[ -n "$source_directory" ]]; then
  source_root="$(cd "$source_directory" && pwd)"
else
  source_root="$install_root/source"
  if command -v git >/dev/null 2>&1; then
    if [[ -d "$source_root/.git" ]]; then
      [[ -z "$(git -C "$source_root" status --porcelain)" ]] || { echo "Portable CLI checkout is dirty: $source_root" >&2; exit 1; }
      git -C "$source_root" fetch --depth 1 origin "$ref"
      git -C "$source_root" checkout --detach FETCH_HEAD
    elif [[ -e "$source_root" ]]; then
      staged_source="$work/source-git"
      git clone --depth 1 --branch "$ref" "$repository" "$staged_source"
      [[ -f "$staged_source/package.json" ]] || { echo "Cloned CLI source lacks package.json" >&2; exit 1; }
      rollback_source="$install_root/.source-rollback.$$.$RANDOM"
      mv "$source_root" "$rollback_source"
      if mv "$staged_source" "$source_root" && [[ -f "$source_root/package.json" ]]; then
        rm -rf "$rollback_source"
      else
        rm -rf "$source_root"
        mv "$rollback_source" "$source_root"
        echo "CLI source replacement failed and was rolled back." >&2
        exit 1
      fi
    else
      git clone --depth 1 --branch "$ref" "$repository" "$source_root"
    fi
    source_commit="$(git -C "$source_root" rev-parse HEAD)"
  else
    archive_base="${repository%.git}"
    curl -fL --retry 3 -o "$work/source.zip" "$archive_base/-/archive/$ref/multiagengorcli-$ref.zip"
    ditto -x -k "$work/source.zip" "$work/source-extract"
    extracted="$(find "$work/source-extract" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [[ -f "$extracted/package.json" ]] || { echo "CLI archive lacks package.json" >&2; exit 1; }
    rollback_source=""
    if [[ -e "$source_root" ]]; then
      rollback_source="$install_root/.source-rollback.$$.$RANDOM"
      mv "$source_root" "$rollback_source"
    fi
    if mv "$extracted" "$source_root" && [[ -f "$source_root/package.json" ]]; then
      [[ -z "$rollback_source" ]] || rm -rf "$rollback_source"
    else
      rm -rf "$source_root"
      [[ -z "$rollback_source" ]] || mv "$rollback_source" "$source_root"
      echo "CLI source replacement failed and was rolled back." >&2
      exit 1
    fi
  fi
fi

if [[ -z "$source_commit" && -d "$source_root/.git" ]] && command -v git >/dev/null 2>&1; then
  source_commit="$(git -C "$source_root" rev-parse HEAD 2>/dev/null || true)"
fi

[[ -f "$source_root/package.json" ]] || { echo "CLI package.json not found." >&2; exit 1; }
engine="$(sed -nE 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$source_root/package.json" | head -n 1)"
package_manager="$(sed -nE 's/.*"packageManager"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$source_root/package.json" | head -n 1)"
[[ "$engine" =~ \>=[[:space:]]*([0-9]+) ]] || { echo "Unsupported Node engine: $engine" >&2; exit 1; }
node_major="${BASH_REMATCH[1]}"
[[ "$package_manager" =~ ^pnpm@([0-9]+\.[0-9]+\.[0-9]+)$ ]] || { echo "Unsupported packageManager: $package_manager" >&2; exit 1; }
pnpm_version="${BASH_REMATCH[1]}"

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
[[ "$(node --version)" == "v$node_major."* ]] || { echo "Selected Node does not satisfy $engine" >&2; exit 1; }
tools_root="$install_root/tools"
npm install --prefix "$tools_root" --no-save --no-package-lock "pnpm@$pnpm_version"
pnpm_entry="$tools_root/node_modules/pnpm/bin/pnpm.cjs"
node "$pnpm_entry" --dir "$source_root" install --frozen-lockfile
node "$pnpm_entry" --dir "$source_root" build
entry="$source_root/dist/bin/multiagentor.js"
[[ -f "$entry" ]] || { echo "Built CLI entrypoint is missing." >&2; exit 1; }
cat > "$launcher" <<EOF
#!/usr/bin/env bash
exec "$node_bin" "$entry" "\$@"
EOF
chmod 0755 "$launcher"
cli_version="$("$launcher" --version)"
"$launcher" --help >/dev/null
printf '{"mode":"installed","platform":"darwin-arm64","invocation":"%s","cliVersion":"%s","nodeVersion":"%s","pnpmVersion":"%s","nodeEngine":"%s","source":"%s","sourceCommit":"%s","repository":"%s","ref":"%s","installRoot":"%s"}\n' \
  "$(json_escape "$launcher")" "$(json_escape "$cli_version")" "$(json_escape "$node_version")" "$(json_escape "$pnpm_version")" "$(json_escape "$engine")" "$(json_escape "$source_root")" "$(json_escape "$source_commit")" "$(json_escape "$repository")" "$(json_escape "$ref")" "$(json_escape "$install_root")"
