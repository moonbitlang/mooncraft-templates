# Minimal Static App

This template is the smallest useful MoonCraft preview shape:

- MoonBit renders the HTML page.
- `mooncraft-preview.sh` writes the page into `preview-dist/`.
- `backend/` serves the preview with a native MoonBit HTTP server.

Run validation:

```sh
moon fmt --check
moon check
moon build
moon test
```

Run the preview:

```sh
./mooncraft-preview.sh 4300
```
