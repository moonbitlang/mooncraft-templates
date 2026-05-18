# MoonBit Multiple Targets

Use `frontend/shared/backend` when a browser app and Native server need the
same MoonBit model.

- `shared/` should stay target-neutral: DTOs, JSON derivations, validation, and
  pure domain logic.
- `frontend/` should set a browser target such as `js` or `wasm`.
- `backend/` should set `native` and own HTTP, filesystem, and process APIs.
- Keep target-specific packages thin. Move code into `shared/` only when both
  sides really use it.

Reference: <https://www.moonbitlang.com/blog/moonbit-multiple-targets>
