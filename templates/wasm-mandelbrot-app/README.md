# Wasm Mandelbrot App

This template focuses on a WebAssembly frontend served by a native MoonBit
preview backend:

- `frontend/` defines render parameters, Mandelbrot math, and Wasm exports.
- `backend/` compiles to Native and serves the preview assets.
- `public/index.html` is the browser shell copied by the preview script.

The preview entrypoint is `mooncraft-preview.sh`.

Run frontend logic tests with:

```sh
moon test --target wasm frontend
```
