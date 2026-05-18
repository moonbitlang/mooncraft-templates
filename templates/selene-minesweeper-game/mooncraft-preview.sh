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

cat > preview-dist/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MoonCraft Minesweeper</title>
  <style>
    html, body { margin: 0; width: 100%; height: 100%; overflow: hidden; background: #101820; }
    canvas { display: block; width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <script type="module" src="/frontend.js"></script>
</body>
</html>
HTML

exec moon run --target native backend -- preview-dist "$port"
