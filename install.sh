dst_fn="$HOME/.superdb/superkit.spq"
mkdir -p "$(dirname "$dst_fn")"

# TODO: Repo isn't public yet
#curl -o "$dst_fn" https://raw.githubusercontent.com/chrismo/superkit/refs/heads/main/dist/superkit.spq

cp -v "$(dirname "${BASH_SOURCE[0]}")/dist/superkit.spq" "$dst_fn"

# just suggest the alias, don't set it up
cat << EOF
Superkit library installed to $dst_fn

Optionally, add this alias to your shell config to run super with superkit's
functions and operators included. To use superkit with super in scripts,
remember to use the include (-I) option when calling super, aliases are not
available in scripts by default.

  alias sk=\"super -I \$HOME/.superdb/superkit.spq\"

Superkit Version $(super -f line -I "$dst_fn" -c 'kversion()') is ready!
EOF
