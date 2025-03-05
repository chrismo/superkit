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
# - Install on clean OS
# - Install on OS with existing superkit
# - Install with redefined XDG_*_HOME
# - Install without PATH including XDG_BIN_HOME
# - Install without `super` or `zq` in PATH
# - Uninstall in all cases

# https://specifications.freedesktop.org/basedir-spec/latest/
declare -r bin_dir=${XDG_BIN_HOME:-$HOME/.local/bin}
declare -r lib_dir=${XDG_DATA_HOME:-$HOME/.local/share}/superkit
declare -r conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}/superkit

for dir in "$bin_dir" "$lib_dir" "$conf_dir"; do
  _ensure_dir_exists "$dir"
done

declare -r root_url="https://raw.githubusercontent.com/chrismo/superkit/refs/heads/main"

_curl_file $root_url/dist/superkit.spq "$lib_dir/superkit.spq"

_curl_file $root_url/dist/sk "$bin_dir/sk" "0755"
_curl_file $root_url/dist/skdoc "$bin_dir/skdoc" "0755"
_curl_file $root_url/dist/skgrok "$bin_dir/skgrok" "0755"
_curl_file $root_url/dist/skgrok_data.jsup "$bin_dir/skgrok_data.jsup"

# TODO: this is dumb - need to package everything up in a tar.gz
for fn in from.md grok.md subqueries.md; do
  _curl_file $root_url/doc/$fn "$lib_dir/doc/$fn"
done

echo "Superkit Version $("$bin_dir"/sk -f line -c 'kversion()') is ready!"

# export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"
