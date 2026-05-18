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
mkdir -p preview-dist/api

moon run cmd/main > preview-dist/index.html
printf '{"status":"ok"}\n' > preview-dist/api/health

exec moon run --target native backend -- preview-dist "$port"
