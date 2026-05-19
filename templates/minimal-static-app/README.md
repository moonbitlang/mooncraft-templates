# Minimal Static App

This template is the smallest useful MoonCraft preview shape:

- MoonBit renders the HTML page.
- `backend/` serves the page directly with a native MoonBit HTTP server.
- `mooncraft-preview.sh` starts the server on the requested port.

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
