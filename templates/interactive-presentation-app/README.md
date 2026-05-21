# Interactive Presentation

This template follows MoonBit's multi-target full-stack pattern:

- `shared/` defines deck, slide, metric, JSON, validation, and navigation logic.
- `frontend/` uses Rabbita, compiles to JavaScript, and imports `shared`.
- `backend/` uses Mocket on Native to serve API data and frontend assets.
- `public/index.html` is the browser shell copied by the preview script.

The sample deck includes fixed layout presets, speaker notes, a presentation
timer, keyboard navigation, automatic metrics refresh, and interactive chart
controls. It also includes a lightweight custom-element 3D viewer that renders a
draggable pink `MoonBit` word with a vendored Three.js runtime and no external
model pipeline.

The preview entrypoint is `mooncraft-preview.sh`.
