#!/usr/bin/env bash

dst_fn="$HOME/.superdb/superkit.spq"

if [ -f "$dst_fn" ]; then
  rm "$dst_fn"
  echo "$dst_fn removed."
else
  echo "$dst_fn not found."
fi
