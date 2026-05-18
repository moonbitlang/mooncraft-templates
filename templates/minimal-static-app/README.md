# Minimal Static App

This template is the smallest useful MoonCraft preview shape:

- MoonBit renders the HTML page.
- `mooncraft-preview.sh` writes the page into `preview-dist/`.
- Python's foreground HTTP server serves the preview on the requested port.

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
