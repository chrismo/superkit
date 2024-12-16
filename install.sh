# support zq, zed or superdb

if [ -f "$HOME/.superdb/superkit.sdb" ]; then
  echo "Application is already installed"
  exit 1
fi

# just suggest the alias, don't set it up, cuz so many danged shells.
