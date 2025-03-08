#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

function read_version_from_src() {
  super -f text -I "$(_script_dir)"/src/version.spq -c "yield sk_version()"
}

function read_tag_from_changelog() {
  super -f text -c "yield version | head 1" changelog.jsup
}

function validate_versions() {
  local -r src_version=$(read_version_from_src)
  local -r log_version=$(read_tag_from_changelog)

  if [ "$src_version" != "$log_version" ]; then
    echo "Version mismatch between src/version.spq <$src_version> and changelog.jsup <$log_version>"
    exit 1
  fi
}

function increment_version() {
  local -r current_version=$(read_version_from_src)
  local -r new_version=$(
    super -f text -c "yield '$current_version'
                      | split(this, '.')
                      | {major: uint32(this[0]), minor: uint32(this[1]), patch: uint32(this[2])}
                      | patch:=patch+1
                      | f'{major}.{minor}.{patch}'"
  )

  sed -i '' -E "s/$current_version/$new_version/g" "$(_script_dir)"/src/version.spq

  new_log=$(super -Z -c "
{
  date:'',
  version:'$new_version',
  super_version:'',
  items:[
    ''
  ]
}
  ")

  mv "$(_script_dir)"/changelog.jsup "$(_script_dir)"/changelog.jsup.bak
  echo "$new_log" >"$(_script_dir)"/changelog.jsup
  super -Z -c 'yield this' "$(_script_dir)"/changelog.jsup.bak \
    >>"$(_script_dir)"/changelog.jsup
  rm "$(_script_dir)"/changelog.jsup.bak

  echo "Incremented version from $current_version to $new_version"
}

function release() {
  echo 'not ready'
  exit 1

  # TODO: https://github.com/chrismo/superkit/issues/32

  # Ensure the GitHub CLI is installed
  if ! command -v gh &>/dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it and try again."
    exit 1
  fi

  local -r repo="chrismo/superkit"

  # TODO: read from changelog
  # TAG="v$(date +'%Y%m%d%H%M%S')"  # Generate a tag based on the current timestamp

  local -r release_name="Release $(read_tag_from_changelog)"

  # shellcheck disable=SC2012
  tar_file=$(ls ./dist/*.tar.gz | sort | tail -n 1) # Get the latest .tar.gz file

  if [[ ! -f "$tar_file" ]]; then
    echo "No .tar.gz file found in the dist directory."
    exit 1
  fi

  # TODO: notes from changelog - start with as-is? or format as markdown?

  # Create a new release
  #gh release create "$TAG" "$tar_file" --repo "$REPO" --title "$release_name" --notes "Automated release for $TAG"

  echo "Release $release_name created and $tar_file uploaded to GitHub."
}

function _usage() {
  grep -E '^function' "${BASH_SOURCE[0]}" | sort
}

function usage() {
  _usage | less -FX
}

if [ $# -eq 0 ]; then
  usage
else
  while getopts "ho:" opt; do
    case $opt in
    h)
      usage
      exit 0
      ;;
    o) opt="$OPTARG" ;;
    \?) # ignore invalid options
      ;;
    esac
  done

  # Remove options processed by getopts, so the remaining args can be handled
  # positionally.
  shift $((OPTIND - 1))

  "$@"
fi
