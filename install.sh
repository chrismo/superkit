# support zq, zed or superdb

# TODO: support XDG here
dst_fn="$HOME/.superdb/superkit.spq"

if [ -f "$dst_fn" ]; then
  echo "Application is already installed"
  exit 1
fi



# just suggest the alias, don't set it up
