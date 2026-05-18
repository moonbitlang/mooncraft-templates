# MoonCraft Runtime Contract

- A generated app workspace is a normal MoonBit project at its root.
- The root `moon.mod.json` should set `preferred-target` for the app.
- Plain `moon fmt`, `moon check`, `moon build`, and `moon test` must pass from
  the project root.
- The root must include executable `mooncraft-preview.sh`.
- `mooncraft-preview.sh` reads `$1` as the port, defaults to `4300`, listens on
  `0.0.0.0:<port>`, and stays in the foreground.
- Serve the user-facing app at `/`.
- Serve `/api/health` when practical. MoonCraft can fall back to `/` for simple
  static previews.
- Full-stack app templates should use `frontend/shared/backend` when both
  browser and server code need the same MoonBit model.
- Selene game templates do not need `shared/` unless the backend also consumes
  game-domain types. Keep the backend as a small static HTTP server.
