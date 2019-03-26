#!/usr/bin/env bash

git_dir="$(git rev-parse --show-toplevel)"
etc_dir="$git_dir/etc"
mkdir -p "$etc_dir"

cd $etc_dir

for i in *.dist
do
    target="$(basename "$i" .dist)"
    [[ -e "$target" ]] && continue
    cp "$i" "$target"

done
