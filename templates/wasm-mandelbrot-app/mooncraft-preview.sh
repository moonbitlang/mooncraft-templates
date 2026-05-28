#!/bin/sh
set -eu

port="${1:-4300}"

case "$port" in
  ""|*[!0-9]*)
    echo "port must be numeric" >&2
    exit 2
    ;;
esac

cd "$(dirname "$0")"
dist_dir="$(pwd)/preview-dist"
rm -rf "$dist_dir"
mkdir -p "$dist_dir"

moon build --target wasm frontend
cp _build/wasm/debug/build/frontend/frontend.wasm "$dist_dir/frontend.wasm"
cp public/index.html "$dist_dir/index.html"

exec moon run --target native backend -- "$dist_dir" "$port"
