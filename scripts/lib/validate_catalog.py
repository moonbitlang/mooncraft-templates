#!/usr/bin/env python3
import json
from pathlib import Path
import sys

VALID_SHAPES = {"native-only", "frontend/backend", "frontend/shared/backend"}
VALID_FRONTEND_FRAMEWORKS = {"rabbita", "selene-webgpu", "wasm-exports"}
VALID_BACKEND_FRAMEWORKS = {"async-http", "mocket"}
REQUIRED_USE_CASES = {
    "minimal": {"web"},
    "fullstack": {"web", "fullstack"},
    "wasm": {"web", "wasm"},
    "game": {"web", "games"},
}
FRAMEWORK_DEPS = {
    "rabbita": "moonbit-community/rabbita",
    "mocket": "oboard/mocket",
    "selene-webgpu": "Milky2018/selene_webgpu",
    "async-http": "moonbitlang/async",
}


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def require_object(value, label):
    require(isinstance(value, dict), f"{label} must be an object")
    return value


def require_string(value, label):
    require(
        isinstance(value, str) and value,
        f"{label} must be a non-empty string",
    )
    return value


def require_string_array(value, label):
    require(
        isinstance(value, list)
        and value
        and all(isinstance(item, str) and item for item in value),
        f"{label} must be a non-empty string array",
    )
    return value


def file_contains(path, text):
    return path.is_file() and text in path.read_text(encoding="utf-8")


def validate_template(root, template):
    for key in (
        "id",
        "name",
        "path",
        "description",
        "category",
        "useCases",
        "architecture",
        "runtime",
        "validation",
    ):
        require(template.get(key), f"catalog template is missing {key}")

    template_id = template["id"]
    require(
        len(template["description"]) >= 80,
        f"{template_id} description is too short",
    )

    category = require_string(template["category"], f"{template_id}.category")
    use_cases = set(require_string_array(template["useCases"], f"{template_id}.useCases"))
    required_use_cases = REQUIRED_USE_CASES.get(category)
    require(required_use_cases is not None, f"{template_id} has unknown category: {category}")
    require(
        required_use_cases.issubset(use_cases),
        f"{template_id} useCases must include: {', '.join(sorted(required_use_cases))}",
    )

    path = validate_path(template_id, template["path"])
    template_dir = root / path
    validate_architecture(root, template_id, template_dir, template["architecture"])
    validate_runtime(template_id, template["runtime"])
    validate_validation(template_id, template_dir, template["architecture"], template["validation"], template["runtime"])
    return path


def validate_path(template_id, raw_path):
    path = Path(raw_path)
    require(
        not path.is_absolute() and ".." not in path.parts,
        f"catalog template path must stay inside repo: {raw_path}",
    )
    require(str(path).startswith("templates/"), f"{template_id} path must be under templates/")
    return path


def validate_architecture(root, template_id, template_dir, architecture):
    architecture = require_object(architecture, f"{template_id}.architecture")
    shape = require_string(architecture.get("shape"), f"{template_id}.architecture.shape")
    require(shape in VALID_SHAPES, f"{template_id} has invalid shape: {shape}")

    has_frontend = (template_dir / "frontend").is_dir()
    has_shared = (template_dir / "shared").is_dir()
    has_backend = (template_dir / "backend").is_dir()
    if shape == "native-only":
        require(not has_frontend, f"{template_id} shape forbids frontend/")
        require(not has_shared, f"{template_id} shape forbids shared/")
        require(has_backend, f"{template_id} shape requires backend/")
        require("frontend" not in architecture, f"{template_id} native-only must not declare frontend")
        require("shared" not in architecture, f"{template_id} native-only must not declare shared")
    elif shape == "frontend/backend":
        require(has_frontend, f"{template_id} shape requires frontend/")
        require(not has_shared, f"{template_id} shape forbids shared/")
        require(has_backend, f"{template_id} shape requires backend/")
        require("frontend" in architecture, f"{template_id} shape requires frontend architecture")
        require("shared" not in architecture, f"{template_id} shape must not declare shared")
    elif shape == "frontend/shared/backend":
        require(has_frontend, f"{template_id} shape requires frontend/")
        require(has_shared, f"{template_id} shape requires shared/")
        require(has_backend, f"{template_id} shape requires backend/")
        require("frontend" in architecture, f"{template_id} shape requires frontend architecture")
        require("shared" in architecture, f"{template_id} shape requires shared architecture")

    moon_mod = json.loads((template_dir / "moon.mod.json").read_text(encoding="utf-8"))
    deps = moon_mod.get("deps", {})
    validate_frontend(template_id, template_dir, architecture.get("frontend"), deps)
    validate_backend(template_id, template_dir, architecture.get("backend"), deps)


def validate_frontend(template_id, template_dir, frontend, deps):
    if frontend is None:
        return
    frontend = require_object(frontend, f"{template_id}.architecture.frontend")
    target = require_string(frontend.get("target"), f"{template_id}.architecture.frontend.target")
    framework = require_string(frontend.get("framework"), f"{template_id}.architecture.frontend.framework")
    require(target in {"js", "wasm"}, f"{template_id} frontend target must be js or wasm")
    require(
        framework in VALID_FRONTEND_FRAMEWORKS,
        f"{template_id} has invalid frontend framework: {framework}",
    )
    require(
        file_contains(template_dir / "frontend" / "moon.pkg", f'supported_targets = "{target}"'),
        f"{template_id} frontend/moon.pkg must declare supported_targets = \"{target}\"",
    )
    dep = FRAMEWORK_DEPS.get(framework)
    if dep is not None:
        require(dep in deps, f"{template_id} frontend framework {framework} requires dependency {dep}")
    if framework == "wasm-exports":
        require(
            file_contains(template_dir / "frontend" / "moon.pkg", '"wasm"'),
            f"{template_id} frontend framework wasm-exports requires wasm link config",
        )


def validate_backend(template_id, template_dir, backend, deps):
    backend = require_object(backend, f"{template_id}.architecture.backend")
    target = require_string(backend.get("target"), f"{template_id}.architecture.backend.target")
    framework = require_string(backend.get("framework"), f"{template_id}.architecture.backend.framework")
    require(target == "native", f"{template_id} backend target must be native")
    require(
        framework in VALID_BACKEND_FRAMEWORKS,
        f"{template_id} has invalid backend framework: {framework}",
    )
    require(
        file_contains(template_dir / "backend" / "moon.pkg", 'supported_targets = "native"'),
        f"{template_id} backend/moon.pkg must declare supported_targets = \"native\"",
    )
    dep = FRAMEWORK_DEPS.get(framework)
    if dep is not None:
        require(dep in deps, f"{template_id} backend framework {framework} requires dependency {dep}")
    if framework == "async-http":
        require(
            file_contains(template_dir / "backend" / "moon.pkg", '"moonbitlang/async/http"'),
            f"{template_id} backend framework async-http requires moonbitlang/async/http import",
        )


def validate_runtime(template_id, runtime):
    runtime = require_object(runtime, f"{template_id}.runtime")
    require(runtime.get("previewScript") == "mooncraft-preview.sh", f"{template_id} runtime.previewScript must be mooncraft-preview.sh")
    require(runtime.get("defaultPort") == 4300, f"{template_id} runtime.defaultPort must be 4300")
    require(runtime.get("host") == "0.0.0.0", f"{template_id} runtime.host must be 0.0.0.0")
    require_string_array(runtime.get("serves"), f"{template_id}.runtime.serves")
    artifacts = runtime.get("artifacts")
    require(
        isinstance(artifacts, list) and all(isinstance(item, str) and item for item in artifacts),
        f"{template_id}.runtime.artifacts must be a string array",
    )


def validate_validation(template_id, template_dir, architecture, validation, runtime):
    validation = require_object(validation, f"{template_id}.validation")
    commands = require_string_array(validation.get("commands"), f"{template_id}.validation.commands")
    for command in ("moon fmt --check", "moon check", "moon build", "moon test"):
        require(command in commands, f"{template_id} validation.commands must include {command}")

    frontend = architecture.get("frontend")
    if frontend is not None:
        target = frontend["target"]
        require(
            f"moon build --target {target} frontend" in commands,
            f"{template_id} validation.commands must include frontend {target} build",
        )
        if target == "wasm" and any((template_dir / "frontend").glob("*_test.mbt")):
            require(
                "moon test --target wasm frontend" in commands,
                f"{template_id} validation.commands must include wasm frontend tests",
            )

    preview_smoke = require_object(validation.get("previewSmoke"), f"{template_id}.validation.previewSmoke")
    smoke_paths = require_string_array(preview_smoke.get("paths"), f"{template_id}.validation.previewSmoke.paths")
    for smoke_path in smoke_paths:
        require(smoke_path in runtime["serves"], f"{template_id} preview smoke path not listed in runtime.serves: {smoke_path}")


def validate_catalog(root):
    catalog_path = root / "catalog.json"
    templates_root = root / "templates"
    with catalog_path.open("r", encoding="utf-8") as handle:
        catalog = json.load(handle)

    templates = catalog.get("templates")
    require(isinstance(templates, list) and templates, "catalog.json must contain a templates array")

    seen_ids = set()
    seen_paths = set()
    rows = []
    for template in templates:
        template_id = require_string(template.get("id"), "template.id")
        require(template_id not in seen_ids, f"duplicate catalog template id: {template_id}")
        seen_ids.add(template_id)
        path = validate_template(root, template)
        require(path not in seen_paths, f"duplicate catalog template path: {path}")
        seen_paths.add(path)
        rows.append((path, template["validation"]["previewSmoke"]["paths"], template["runtime"]["artifacts"]))

    actual_set = {
        str(path.relative_to(root))
        for path in templates_root.iterdir()
        if path.is_dir() and (path / "moon.mod.json").is_file()
    }
    catalog_set = {str(path) for path in seen_paths}
    missing = sorted(catalog_set - actual_set)
    extra = sorted(actual_set - catalog_set)
    require(not missing, "catalog references missing templates: " + ", ".join(missing))
    require(not extra, "templates missing from catalog.json: " + ", ".join(extra))
    return rows


def format_shell_words(paths, label):
    for path in paths:
        require(not any(char.isspace() for char in path), f"{label} cannot contain whitespace: {path}")
    return " ".join(paths)


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: validate_catalog.py <repo-root> <output-list>")
    root = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    rows = validate_catalog(root)
    with output_path.open("w", encoding="utf-8") as output:
        for path, smoke_paths, artifacts in rows:
            template_dir = root / path
            require(
                (template_dir / "mooncraft-preview.sh").is_file(),
                f"missing mooncraft-preview.sh in {path}",
            )
            print(
                "\t".join(
                    (
                        str(template_dir),
                        format_shell_words(smoke_paths, f"{path} smoke path"),
                        format_shell_words(artifacts, f"{path} artifact"),
                    )
                ),
                file=output,
            )


if __name__ == "__main__":
    main()
