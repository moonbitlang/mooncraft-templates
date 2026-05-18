# MoonBit Style

- Use `let mut` only when the binding itself is reassigned.
- Arrays, maps, buffers, and other mutable objects can usually be bound with
  plain `let` when their contents mutate.
- Keep MoonBit packages small and cohesive. File names organize code; they do
  not create namespaces.
- Prefer explicit request, response, state, and rendering helpers over dynamic
  stringly typed plumbing.
- Keep `main` thin. Put reusable behavior in the package so tests can exercise
  it directly.
