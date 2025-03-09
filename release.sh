#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

function read_version_from_src() {
  super -f text -I "$(_script_dir)"/src/version.spq -c "yield sk_version()"
}

function read_version_from_changelog() {
  super -f text -c "yield version | head 1" changelog.jsup
}

function validate_versions() {
  local -r src_version=$(read_version_from_src)
  local -r log_version=$(read_version_from_changelog)

  if [ "$src_version" != "$log_version" ]; then
    echo "Version mismatch between src/version.spq <$src_version> and changelog.jsup <$log_version>"
    exit 1
  fi
}

function bump_next_version() {
  local -r current_version=$(read_version_from_src)
  local -r new_version=$(
    super -f text -c "yield '$current_version'
                      | split(this, '.')
                      | {major: uint32(this[0]),
                         minor: uint32(this[1]),
                         patch: uint32(this[2])}
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

function set_install_version() {
  local -r new_version=$(read_version_from_src)

  sed -i '' -E "s/declare -r version=\"\$\{RELEASE:-.*\}\"/declare -r version=\"\$\{RELEASE:-$new_version\}\"/" \
    "$(_script_dir)"/install.sh

  echo "Install version set to $new_version"
}

function pre-release() {
  release "-$(git describe --tags --dirty --always)"
}

function release() {
  local -r pre_release=${1:-}

  local -r current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [ -z "$pre_release" ]; then
    if [ "$current_branch" != "main" ]; then
      echo "ERROR: Cannot do a normal release from non-main branch: <$current_branch>"
      exit 1
    fi
  else
    pre_release_opt="--prerelease"
    branch_opt="--target $current_branch"
  fi

  # TODO: https://github.com/chrismo/superkit/issues/32

  # Ensure the GitHub CLI is installed
  if ! command -v gh &>/dev/null; then
    echo "ERROR: GitHub CLI (gh) is not installed. Please install it and try again."
    exit 1
  fi

  local -r repo="chrismo/superkit"
  local -r tag="$(read_version_from_changelog)$pre_release"

  if echo "$tag" | grep -q "dirty"; then
    echo "ERROR: The tag cannot include 'dirty'."
    exit 1
  fi

  # shellcheck disable=SC2012
  tar_file=$(ls ./dist/*.tar.gz | sort | tail -n 1) # Get the latest .tar.gz file

  if [[ ! -f "$tar_file" ]]; then
    echo "No .tar.gz file found in the dist directory."
    exit 1
  fi

  local -r notes="
\`\`\`
$(super -Z -c "head 1" changelog.jsup)
\`\`\`
"

  gh release create "$tag" "$tar_file" --repo "$repo" \
    --title "$tag" --notes "$notes" "$pre_release_opt" "$branch_opt"

  echo "Release $tag created and $tar_file uploaded to GitHub."
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
