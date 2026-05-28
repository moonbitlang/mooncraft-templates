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
mkdir -p "$dist_dir/vendor"

moon build --target js frontend
cp _build/js/debug/build/frontend/frontend.js "$dist_dir/frontend.js"
cp public/index.html "$dist_dir/index.html"
cp public/object-viewer.js "$dist_dir/object-viewer.js"
cp public/vendor/three.module.js "$dist_dir/vendor/three.module.js"
cp public/vendor/three.core.js "$dist_dir/vendor/three.core.js"
cp public/vendor/FontLoader.js "$dist_dir/vendor/FontLoader.js"
cp public/vendor/TextGeometry.js "$dist_dir/vendor/TextGeometry.js"
cp public/vendor/helvetiker_bold.typeface.json "$dist_dir/vendor/helvetiker_bold.typeface.json"

exec moon run --target native backend -- "$dist_dir" "$port"
