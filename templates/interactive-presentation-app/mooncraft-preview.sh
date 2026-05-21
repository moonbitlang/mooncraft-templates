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
mkdir -p preview-dist/vendor

moon build --target js frontend
cp _build/js/debug/build/frontend/frontend.js preview-dist/frontend.js
cp public/index.html preview-dist/index.html
cp public/object-viewer.js preview-dist/object-viewer.js
cp public/vendor/three.module.js preview-dist/vendor/three.module.js
cp public/vendor/three.core.js preview-dist/vendor/three.core.js
cp public/vendor/FontLoader.js preview-dist/vendor/FontLoader.js
cp public/vendor/TextGeometry.js preview-dist/vendor/TextGeometry.js
cp public/vendor/helvetiker_bold.typeface.json preview-dist/vendor/helvetiker_bold.typeface.json

exec moon run --target native backend -- preview-dist "$port"
