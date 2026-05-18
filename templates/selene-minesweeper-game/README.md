# Selene Minesweeper Game

This template packages a small Selene game for MoonCraft:

- `frontend/` contains the game and compiles to JavaScript with
  `selene_webgpu` platform overrides.
- `backend/` is a minimal Native HTTP server built with `moonbitlang/async/http`.
- `mooncraft-preview.sh` builds the game assets and starts the backend server.

The game code is adapted from `../gameparty/minesweeper`.
