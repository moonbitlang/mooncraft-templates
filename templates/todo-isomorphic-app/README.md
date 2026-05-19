# Todo Isomorphic App

This template follows MoonBit's multi-target full-stack pattern:

- `shared/` defines the domain model, JSON shape, and validation.
- `frontend/` compiles to JavaScript and imports `shared`.
- `backend/` compiles to Native, serves the API and static frontend assets.
- `public/index.html` is the browser shell copied by the preview script.

The preview entrypoint is `mooncraft-preview.sh`.
