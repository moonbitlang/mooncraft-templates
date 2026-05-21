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
rm -rf preview-dist
mkdir -p preview-dist

moon build --target js frontend
cp _build/js/debug/build/frontend/frontend.js preview-dist/frontend.js
cp public/index.html preview-dist/index.html

exec moon run --target native backend -- preview-dist "$port"
