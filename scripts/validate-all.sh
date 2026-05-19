#!/bin/sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ ! -f "$root_dir/catalog.json" ]; then
  echo "missing catalog.json" >&2
  exit 1
fi

template_list=$(mktemp)

cleanup_catalog() {
  rm -f "$template_list"
}

trap cleanup_catalog EXIT INT TERM

python3 - "$root_dir" "$template_list" <<'PY'
import json
from pathlib import Path
import sys

root = Path(sys.argv[1])
output_path = Path(sys.argv[2])
catalog_path = root / "catalog.json"
templates_root = root / "templates"

with catalog_path.open("r", encoding="utf-8") as handle:
    catalog = json.load(handle)

templates = catalog.get("templates")
if not isinstance(templates, list) or not templates:
    raise SystemExit("catalog.json must contain a templates array")

seen_ids = set()
seen_paths = set()
catalog_paths = []

for template in templates:
    for key in ("id", "path", "description"):
        if not template.get(key):
            raise SystemExit(f"catalog template is missing {key}")
    template_id = template["id"]
    if template_id in seen_ids:
        raise SystemExit(f"duplicate catalog template id: {template_id}")
    seen_ids.add(template_id)

    raw_path = template["path"]
    path = Path(raw_path)
    if path.is_absolute() or ".." in path.parts:
        raise SystemExit(f"catalog template path must stay inside repo: {raw_path}")
    if path in seen_paths:
        raise SystemExit(f"duplicate catalog template path: {raw_path}")
    seen_paths.add(path)
    catalog_paths.append(path)

catalog_set = {str(path) for path in catalog_paths}
actual_set = {
    str(path.relative_to(root))
    for path in templates_root.iterdir()
    if path.is_dir() and (path / "moon.mod.json").is_file()
}

missing = sorted(catalog_set - actual_set)
extra = sorted(actual_set - catalog_set)
if missing:
    raise SystemExit("catalog references missing templates: " + ", ".join(missing))
if extra:
    raise SystemExit("templates missing from catalog.json: " + ", ".join(extra))

with output_path.open("w", encoding="utf-8") as output:
    for path in catalog_paths:
        template_dir = root / path
        if not (template_dir / "mooncraft-preview.sh").is_file():
            raise SystemExit(f"missing mooncraft-preview.sh in {path}")
        print(template_dir, file=output)
PY

while IFS= read -r template_dir; do
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
        if find frontend \( -name '*_test.mbt' -o -name '*_wbtest.mbt' \) | grep -q .; then
          moon test --target wasm frontend
        fi
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
done < "$template_list"

echo "all templates validated"
