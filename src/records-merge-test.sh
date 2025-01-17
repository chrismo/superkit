#!/usr/bin/env bash

set -euo pipefail

zq -I merge_records.spq '[{a:1},{b:2},{c:3},{d:4}] | merge_records()'
zq -I merge_records.spq '[{a:1},{b:"sandwich",c:333}] | merge_records()'
zq -I merge_records.spq '[{a:1},{b:{c:333}}] | merge_records()'
