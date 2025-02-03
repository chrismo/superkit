# support zq, zed or superdb

# TODO: support XDG here? it's arguable this isn't user-data ... it's
# _installed_ by the user, but the data in the library doesn't belong to the
# user strictly speaking.

dst_fn="$HOME/.superdb/superkit.spq"
mkdir -p "$(dirname "$dst_fn")"

# TODO: Repo isn't public yet
#curl -o "$dst_fn" https://raw.githubusercontent.com/chrismo/superkit/refs/heads/main/dist/superkit.spq

cp -v "$(dirname "${BASH_SOURCE[0]}")/dist/superkit.spq" "$dst_fn"

echo "Superkit library installed to $dst_fn"
echo

# TODO: Run test to output version, to make sure no formatting errors are present?

# just suggest the alias, don't set it up
echo "Optionally, add this alias to your shell config so superkit is always available."
echo
echo "  alias super=\"super -I \$HOME/.superdb/superkit.spq\""
echo
