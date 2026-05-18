# MoonCraft Templates

This repository is a small knowledge base for agents that generate MoonBit apps
for MoonCraft.

MoonCraft does not use hidden platform scaffolds. Templates here are readable
examples that agents can study, copy from, and adapt when the user asks for a
similar app shape.

## Rules

- Templates are read-only examples, not automatic project seeds.
- Every template is a real MoonBit project with its own `moon.mod.json`.
- Every template must pass `moon fmt --check`, `moon check`, `moon build`, and
  relevant `moon test` runs from the template root.
- Every template root must include executable `mooncraft-preview.sh`.
- `mooncraft-preview.sh` must accept the first CLI argument as the port, default
  to `4300`, listen on `0.0.0.0:<port>`, and keep the server process in the
  foreground.
- Use `let mut` only when rebinding a variable. Do not use it just because an
  object has mutable state.
- Keep examples small enough for an agent to understand quickly.

## Layout

- `catalog.json` indexes the available templates.
- `templates/` contains runnable MoonBit app examples.
- `knowledge/` contains concise MoonBit and MoonCraft guidance.
- `scripts/validate-all.sh` validates every template.

Run all checks:

```sh
./scripts/validate-all.sh
```
