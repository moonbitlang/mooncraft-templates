#!/bin/sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ ! -f "$root_dir/catalog.json" ]; then
  echo "missing catalog.json" >&2
  exit 1
fi

python3 - "$root_dir/catalog.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    catalog = json.load(handle)

if not isinstance(catalog.get("templates"), list):
    raise SystemExit("catalog.json must contain a templates array")

for template in catalog["templates"]:
    for key in ("id", "path", "description"):
        if not template.get(key):
            raise SystemExit(f"catalog template is missing {key}")
PY

found=0
for template_dir in "$root_dir"/templates/*; do
  [ -d "$template_dir" ] || continue
  [ -f "$template_dir/moon.mod.json" ] || continue
  found=1

  echo "==> $(basename "$template_dir")"

  if [ ! -x "$template_dir/mooncraft-preview.sh" ]; then
    echo "missing executable mooncraft-preview.sh in $template_dir" >&2
    exit 1
  fi

  (
    cd "$template_dir"
    moon fmt --check
    moon check
    moon build
    moon test
    if [ -d frontend ]; then
      if grep -q 'supported_targets = "js"' frontend/moon.pkg; then
        moon build --target js frontend
      fi
      if grep -q 'supported_targets = "wasm"' frontend/moon.pkg; then
        moon build --target wasm frontend
      fi
    fi
  )

  port=$(python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
)
  log_file=$(mktemp)
  "$template_dir/mooncraft-preview.sh" "$port" >"$log_file" 2>&1 &
  preview_pid=$!

  cleanup_preview() {
    kill "$preview_pid" >/dev/null 2>&1 || true
    wait "$preview_pid" >/dev/null 2>&1 || true
    rm -f "$log_file"
  }

  ready=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl -fsS "http://127.0.0.1:$port/" >/dev/null 2>&1; then
      ready=1
      break
    fi
    if ! kill -0 "$preview_pid" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if [ "$ready" -ne 1 ]; then
    echo "preview did not become ready for $template_dir" >&2
    cat "$log_file" >&2
    cleanup_preview
    exit 1
  fi

  if ! curl -fsS "http://127.0.0.1:$port/api/health" >/dev/null 2>&1; then
    echo "preview health endpoint failed for $template_dir" >&2
    cat "$log_file" >&2
    cleanup_preview
    exit 1
  fi

  cleanup_preview
done

if [ "$found" -ne 1 ]; then
  echo "no templates found" >&2
  exit 1
fi

echo "all templates validated"
