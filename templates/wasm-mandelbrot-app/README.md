# Wasm Mandelbrot App

This template keeps the same full-stack shape as the MoonBit multi-target
workflow, but gives the frontend a WebAssembly compute core:

- `shared/` defines render parameters and pure Mandelbrot math.
- `frontend/` compiles to Wasm and exports pixel color functions.
- `backend/` compiles to Native and serves the preview assets.

The preview entrypoint is `mooncraft-preview.sh`.
