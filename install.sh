function _ensure_dir_exists() {
  local -r dirname="$1"

  if [ ! -d "$dirname" ]; then
    install -d -m 0700 "$dirname"
  fi
}

function _curl_file() {
  local -r url="$1"
  local -r dst_fn="$2"
  local -r chmod="${3:-}"

  mkdir -p "$(dirname "$dst_fn")"

  curl -o "$dst_fn" "$url"
  if [ -n "$chmod" ]; then
    chmod "$chmod" "$dst_fn"
  fi
}

# Test plan:
# - clean OS
# - OS with existing superkit
# - redefined XDG_*_HOME
# - no PATH to XDG_BIN_HOME
# - without `super` or `zq` in PATH
# - Uninstall in all cases

# skgrok
# - test matrix of fzf | PAGER | less
# -                super | zq

# skops
# - test matrix of fzf | PAGER | less
# -                super | zq

# skdoc
# - test matrix of bat | glow | PAGER | less

# https://specifications.freedesktop.org/basedir-spec/latest/
declare -r bin_dir=${XDG_BIN_HOME:-$HOME/.local/bin}
declare -r lib_dir=${XDG_DATA_HOME:-$HOME/.local/share}/superkit
declare -r conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}/superkit

for dir in "$bin_dir" "$lib_dir" "$conf_dir"; do
  _ensure_dir_exists "$dir"
done

declare dst_dir
dst_dir=$(mktemp -d)
echo "$dst_dir"

# Ensure the temporary directory is removed on exit
trap 'rm -rf "$dst_dir"' EXIT

if [ -z "${LOCAL_INSTALL}" ]; then
  declare -r root_url="https://raw.githubusercontent.com/chrismo/superkit/refs/heads/main"
  curl -s -o "$dst_dir"/superkit.tar.gz $root_url/dist/superkit.tar.gz
else
  cp "$(dirname "${BASH_SOURCE[0]}")"/dist/superkit.tar.gz "$dst_dir"/superkit.tar.gz
fi

mkdir "$dst_dir/superkit/"
tar -C "$dst_dir/superkit/" -xzvf "$dst_dir"/superkit.tar.gz

cp -v "$dst_dir"/superkit/bin/* "$bin_dir"
cp -vR "$dst_dir"/superkit/lib/* "$lib_dir"

echo "SuperKit Version $("$bin_dir"/sk -f line -c 'sk_version()') is ready!"

# export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"
