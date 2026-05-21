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

python3 "$root_dir/scripts/lib/validate_catalog.py" "$root_dir" "$template_list"

while IFS="$(printf '\t')" read -r template_dir smoke_paths artifacts; do
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

  port=$(python3 "$root_dir/scripts/lib/free_port.py")
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

  for smoke_path in $smoke_paths; do
    if ! curl -fsS "http://127.0.0.1:$port$smoke_path" >/dev/null 2>&1; then
      echo "preview smoke path failed for $template_dir: $smoke_path" >&2
      cat "$log_file" >&2
      cleanup_preview
      exit 1
    fi
  done

  for artifact in $artifacts; do
    if [ ! -f "$template_dir/$artifact" ]; then
      echo "preview artifact missing for $template_dir: $artifact" >&2
      cat "$log_file" >&2
      cleanup_preview
      exit 1
    fi
  done

  cleanup_preview
done < "$template_list"

echo "all templates validated"
