#!/usr/bin/env bash
# Install an official SuperDB `super` release binary.
#
# Usage: scripts/install-super.sh [version] [dest-dir]
#
#   version   e.g. 0.4.0 or v0.4.0 (default: contents of .superdb-version)
#   dest-dir  where to put `super` (default: ~/.local/bin)
#
# Downloads super-v<version>.<os>-<arch>.tar.gz from
# https://github.com/superdb/super/releases (linux and darwin, amd64 and arm64).

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${1:-$(tr -d '[:space:]' < "$repo_root/.superdb-version")}"
version="${version#v}"
dest="${2:-$HOME/.local/bin}"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64 | amd64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

url="https://github.com/superdb/super/releases/download/v${version}/super-v${version}.${os}-${arch}.tar.gz"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $url" >&2
curl -fsSL -o "$tmp/super.tar.gz" "$url"
tar -xzf "$tmp/super.tar.gz" -C "$tmp" super

mkdir -p "$dest"
install -m 0755 "$tmp/super" "$dest/super"
"$dest/super" --version
