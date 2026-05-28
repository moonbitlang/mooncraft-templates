#!/usr/bin/env python3
import json
from pathlib import Path
import re
import sys

VALID_FRONTEND_FRAMEWORKS = {"rabbita", "selene-webgpu", "wasm-exports"}
VALID_BACKEND_FRAMEWORKS = {"async-http", "mocket"}
REQUIRED_KEYS = {"id", "name", "path", "description", "category", "keywords"}
REQUIRED_KEYWORDS = {
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
PUBLIC_ABSOLUTE_PATH_PATTERNS = [
    re.compile(r"""\b(?:src|href)\s*=\s*["']/"""),
    re.compile(r"""\bfetch\(\s*["']/"""),
    re.compile(r"""\bimport\(\s*["']/"""),
    re.compile(r"""\bnew\s+Worker\(\s*["']/"""),
    re.compile(r"""\bloadAsync\(\s*["']/"""),
    re.compile(r"""\bfrom\s+["']/"""),
    re.compile(r"""\burl\(\s*["']?/"""),
]
FRONTEND_ABSOLUTE_API_PATTERN = re.compile(
    r"""@http\.(?:get|post|patch|delete|put)\(\s*"/"""
)


def require(condition, message):
    if not condition:
        raise SystemExit(message)


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


def load_moon_mod_deps(template_id, template_dir):
    moon_mod_path = template_dir / "moon.mod"
    moon_mod_json_path = template_dir / "moon.mod.json"
    if moon_mod_path.is_file():
        text = moon_mod_path.read_text(encoding="utf-8")
        match = re.search(r"""(?ms)^import\s*\{(?P<body>.*?)^\}""", text)
        if match is None:
            imports = []
        else:
            imports = re.findall(r'"([^"]+)"', match.group("body"))
        require(
            isinstance(imports, list),
            f"{template_id} moon.mod import must be an array",
        )
        deps = {}
        for item in imports:
            require(
                isinstance(item, str) and item,
                f"{template_id} moon.mod import entries must be strings",
            )
            dep_name = item.split("@", 1)[0]
            deps[dep_name] = item
        return deps

    require(
        moon_mod_json_path.is_file(),
        f"{template_id} requires moon.mod or moon.mod.json",
    )
    moon_mod = json.loads(moon_mod_json_path.read_text(encoding="utf-8"))
    deps = moon_mod.get("deps", {})
    require(
        isinstance(deps, dict),
        f"{template_id} moon.mod.json deps must be an object",
    )
    return deps


def validate_template(root, template):
    require(
        set(template.keys()) == REQUIRED_KEYS,
        "catalog template fields must be exactly: " + ", ".join(sorted(REQUIRED_KEYS)),
    )
    for key in REQUIRED_KEYS:
        require(template.get(key), f"catalog template is missing {key}")

    template_id = template["id"]
    require(
        len(template["description"]) >= 80,
        f"{template_id} description is too short",
    )

    category = require_string(template["category"], f"{template_id}.category")
    keywords = set(require_string_array(template["keywords"], f"{template_id}.keywords"))
    required_keywords = REQUIRED_KEYWORDS.get(category)
    require(required_keywords is not None, f"{template_id} has unknown category: {category}")
    require(
        required_keywords.issubset(keywords),
        f"{template_id} keywords must include: {', '.join(sorted(required_keywords))}",
    )

    path = validate_path(template_id, template["path"])
    template_dir = root / path
    validate_relative_client_paths(template_id, template_dir)
    validate_preview_script(template_id, template_dir)
    architecture = validate_architecture(root, template_id, template_dir)
    artifacts = expected_artifacts(template_dir, architecture)
    smoke_paths = expected_smoke_paths(artifacts)
    return path, smoke_paths, artifacts


def validate_relative_client_paths(template_id, template_dir):
    public_dir = template_dir / "public"
    if public_dir.is_dir():
        for path in public_dir.rglob("*"):
            if path.suffix not in {".html", ".js", ".css"}:
                continue
            text = path.read_text(encoding="utf-8")
            for pattern in PUBLIC_ABSOLUTE_PATH_PATTERNS:
                require(
                    pattern.search(text) is None,
                    f"{template_id} browser asset paths must be relative: {path}",
                )

    frontend_dir = template_dir / "frontend"
    if frontend_dir.is_dir():
        for path in frontend_dir.rglob("*.mbt"):
            text = path.read_text(encoding="utf-8")
            require(
                FRONTEND_ABSOLUTE_API_PATTERN.search(text) is None,
                f"{template_id} frontend fetch API paths must be relative: {path}",
            )


def validate_preview_script(template_id, template_dir):
    script_path = template_dir / "mooncraft-preview.sh"
    require(script_path.is_file(), f"{template_id} requires mooncraft-preview.sh")
    text = script_path.read_text(encoding="utf-8")
    if "preview-dist" not in text or "moon run --target native backend" not in text:
        return
    require(
        'dist_dir="$(pwd)/preview-dist"' in text,
        f"{template_id} preview script must resolve preview-dist to an absolute path",
    )
    require(
        re.search(r"--\s+preview-dist(?:\s|$)", text) is None,
        f"{template_id} preview script must not pass relative preview-dist to backend",
    )
    require(
        '-- "$dist_dir" "$port"' in text,
        f"{template_id} preview script must pass absolute dist_dir to backend",
    )


def validate_path(template_id, raw_path):
    path = Path(raw_path)
    require(
        not path.is_absolute() and ".." not in path.parts,
        f"catalog template path must stay inside repo: {raw_path}",
    )
    require(str(path).startswith("templates/"), f"{template_id} path must be under templates/")
    return path


def validate_architecture(root, template_id, template_dir):
    has_frontend = (template_dir / "frontend").is_dir()
    has_shared = (template_dir / "shared").is_dir()
    has_backend = (template_dir / "backend").is_dir()
    require(has_backend, f"{template_id} requires backend/")
    if has_frontend and has_shared:
        shape = "frontend/shared/backend"
    elif has_frontend:
        shape = "frontend/backend"
    else:
        shape = "native-only"

    if shape == "native-only":
        require(not has_shared, f"{template_id} native-only template must not have shared/")
    elif shape == "frontend/backend":
        require(not has_shared, f"{template_id} frontend/backend template must not have shared/")
    elif shape == "frontend/shared/backend":
        require(has_shared, f"{template_id} frontend/shared/backend template requires shared/")

    deps = load_moon_mod_deps(template_id, template_dir)
    frontend = validate_frontend(template_id, template_dir, deps)
    backend = validate_backend(template_id, template_dir, deps)
    return {"shape": shape, "frontend": frontend, "backend": backend}


def validate_frontend(template_id, template_dir, deps):
    frontend_pkg = template_dir / "frontend" / "moon.pkg"
    if not frontend_pkg.is_file():
        return None
    pkg_text = frontend_pkg.read_text(encoding="utf-8")
    if 'supported_targets = "js"' in pkg_text:
        target = "js"
    elif 'supported_targets = "wasm"' in pkg_text:
        target = "wasm"
    else:
        raise SystemExit(f"{template_id} frontend/moon.pkg must declare js or wasm supported_targets")

    if target == "wasm":
        framework = "wasm-exports"
    elif "moonbit-community/rabbita" in deps:
        framework = "rabbita"
    elif "Milky2018/selene_webgpu" in deps:
        framework = "selene-webgpu"
    else:
        raise SystemExit(f"{template_id} frontend framework cannot be inferred from moon.mod deps")

    require(
        framework in VALID_FRONTEND_FRAMEWORKS,
        f"{template_id} has invalid frontend framework: {framework}",
    )
    dep = FRAMEWORK_DEPS.get(framework)
    if dep is not None:
        require(dep in deps, f"{template_id} frontend framework {framework} requires dependency {dep}")
    if framework == "wasm-exports":
        require(
            file_contains(template_dir / "frontend" / "moon.pkg", '"wasm"'),
            f"{template_id} frontend framework wasm-exports requires wasm link config",
        )
    return {"target": target, "framework": framework}


def validate_backend(template_id, template_dir, deps):
    backend_pkg = template_dir / "backend" / "moon.pkg"
    require(backend_pkg.is_file(), f"{template_id} requires backend/moon.pkg")
    pkg_text = backend_pkg.read_text(encoding="utf-8")
    require(
        'supported_targets = "native"' in pkg_text,
        f"{template_id} backend/moon.pkg must declare supported_targets = \"native\"",
    )
    if '"oboard/mocket"' in pkg_text:
        framework = "mocket"
    elif '"moonbitlang/async/http"' in pkg_text:
        framework = "async-http"
    else:
        raise SystemExit(f"{template_id} backend framework cannot be inferred from backend/moon.pkg")
    require(
        framework in VALID_BACKEND_FRAMEWORKS,
        f"{template_id} has invalid backend framework: {framework}",
    )
    dep = FRAMEWORK_DEPS.get(framework)
    if dep is not None:
        require(dep in deps, f"{template_id} backend framework {framework} requires dependency {dep}")
    if framework == "async-http":
        require(
            file_contains(template_dir / "backend" / "moon.pkg", '"moonbitlang/async/http"'),
            f"{template_id} backend framework async-http requires moonbitlang/async/http import",
        )
    return {"target": "native", "framework": framework}


def expected_artifacts(template_dir, architecture):
    frontend = architecture["frontend"]
    if frontend is None:
        return []
    if frontend["target"] == "js":
        artifacts = ["preview-dist/index.html", "preview-dist/frontend.js"]
    else:
        artifacts = ["preview-dist/index.html", "preview-dist/frontend.wasm"]

    public_dir = template_dir / "public"
    if public_dir.is_dir():
        for path in sorted(public_dir.rglob("*")):
            if path.is_file():
                relative = path.relative_to(public_dir)
                artifact = "preview-dist/" + relative.as_posix()
                if artifact not in artifacts:
                    artifacts.append(artifact)
    return artifacts


def expected_smoke_paths(artifacts):
    paths = ["/", "/api/health"]
    for artifact in artifacts:
        if artifact == "preview-dist/index.html":
            continue
        paths.append("/" + artifact.removeprefix("preview-dist/"))
    return paths


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
        path, smoke_paths, artifacts = validate_template(root, template)
        require(path not in seen_paths, f"duplicate catalog template path: {path}")
        seen_paths.add(path)
        rows.append((path, smoke_paths, artifacts))

    actual_set = {
        str(path.relative_to(root))
        for path in templates_root.iterdir()
        if path.is_dir() and ((path / "moon.mod").is_file() or (path / "moon.mod.json").is_file())
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
