# support zq, zed or superdb

# TODO: check-in after release to confirm file extension.
# TODO: support XDG here
if [ -f "$HOME/.superdb/superkit.sdb" ]; then
  echo "Application is already installed"
  exit 1
fi

# just suggest the alias, don't set it up, cuz so many danged shells.
