#!/usr/bin/env bash

set -euo pipefail

  declare record name spq_fn

for fn in ./src/*spq; do
  while IFS=$'\n' read -r record; do
    name=$(echo "$record" | zq -f text 'yield this.name' -)
    spq_fn=$(echo "$record" | zq -f text 'yield this.filename' -)

    super -z -I ./src/skdoc.spq -I "$spq_fn" -c "$name()"
  done < <(
    super -i line -z -I ./src/skdoc.spq \
      -c "skdoc_parse_file_contents(this) | filename:='$fn'" "$fn"
  )
done
