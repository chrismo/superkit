#!/usr/bin/env bash

# https://specifications.freedesktop.org/basedir-spec/latest/
declare -r bin_dir=${XDG_BIN_HOME:-$HOME/.local/bin}
declare -r lib_dir=${XDG_DATA_HOME:-$HOME/.local/share}/superkit
declare -r conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}/superkit

# TODO: dryrun by default

rm -v "$bin_dir"/sk*
rm -vrf "$lib_dir"
rm -vrf "$conf_dir"
