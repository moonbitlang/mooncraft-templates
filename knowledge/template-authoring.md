# Template Authoring

- A template is a working example, not hidden scaffolding.
- Keep only source, docs, and small assets needed to understand the example.
- Do not commit `_build/`, `.mooncakes/`, generated lock caches, or preview
  output directories.
- Keep each preview script boring and inspectable.
- Validate a template from its own root before adding it to `catalog.json`.
- Keep `catalog.json` and `templates/*/moon.mod.json` in one-to-one sync.
- Keep catalog entries as indexes only: `id`, `name`, `path`, `description`,
  `category`, and `keywords`.
