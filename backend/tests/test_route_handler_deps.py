"""
Guard against calling a FastAPI route handler as a plain function.

FastAPI only resolves ``Depends``/``Query``/``Header`` defaults when it invokes a
handler through the router. Calling one handler directly from another (a common
way to alias an endpoint) leaves any omitted parameter holding the raw marker
object instead of the resolved value, which fails at the first attribute access
far away from the real mistake.

Regression: ``GET /posts/{id}/conversation`` called ``list_post_comments`` with
two of three arguments, so ``current_user`` stayed a ``Depends`` object and the
route returned 500 while never resolving the caller's identity.
"""

from __future__ import annotations

import ast
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent

SERVICE_DIRS = (
    "activity-backend",
    "community-backend",
    "main-backend",
    "map-backend",
)

ROUTE_DECORATORS = {"get", "post", "put", "delete", "patch"}
DEPENDENCY_MARKERS = {
    "Body",
    "Cookie",
    "Depends",
    "File",
    "Form",
    "Header",
    "Path",
    "Query",
    "Security",
}


def _source_files() -> list[Path]:
    files: list[Path] = []
    for service in SERVICE_DIRS:
        root = BACKEND_DIR / service
        if not root.is_dir():
            continue
        for path in root.rglob("*.py"):
            parts = set(path.parts)
            if "tests" in parts or ".venv" in parts or "__pycache__" in parts:
                continue
            files.append(path)
    return sorted(files)


def _dependency_params(func: ast.FunctionDef | ast.AsyncFunctionDef) -> list[str]:
    """Names of parameters whose default is a FastAPI dependency marker.

    strict=True on purpose: padding makes the two lists the same length by
    construction, so a mismatch means an argument shape this function does not
    model (positional-only parameters, say) and silently mis-pairing names with
    defaults would make the whole check quietly wrong.
    """
    args = func.args.args + func.args.kwonlyargs
    padding = [None] * (len(func.args.args) - len(func.args.defaults))
    defaults = padding + list(func.args.defaults) + list(func.args.kw_defaults)
    return [
        arg.arg
        for arg, default in zip(args, defaults, strict=True)
        if isinstance(default, ast.Call)
        and isinstance(default.func, ast.Name)
        and default.func.id in DEPENDENCY_MARKERS
    ]


def _route_handlers(
    tree: ast.Module,
) -> dict[str, tuple[int, list[str], int]]:
    """Map handler name -> (line, dependency params, total params)."""
    handlers: dict[str, tuple[int, list[str], int]] = {}
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        is_route = any(
            isinstance(dec, ast.Call)
            and isinstance(dec.func, ast.Attribute)
            and dec.func.attr in ROUTE_DECORATORS
            for dec in node.decorator_list
        )
        if not is_route:
            continue
        deps = _dependency_params(node)
        if deps:
            total = len(node.args.args) + len(node.args.kwonlyargs)
            handlers[node.name] = (node.lineno, deps, total)
    return handlers


def test_route_handlers_are_not_called_with_unresolved_dependencies() -> None:
    violations: list[str] = []

    for path in _source_files():
        try:
            tree = ast.parse(path.read_text())
        except SyntaxError:  # pragma: no cover - a broken file fails elsewhere
            continue

        handlers = _route_handlers(tree)
        if not handlers:
            continue

        for node in ast.walk(tree):
            if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)):
                continue
            if node.func.id not in handlers:
                continue
            defined_at, deps, total = handlers[node.func.id]
            supplied = len(node.args) + len(node.keywords)
            if supplied < total:
                violations.append(
                    f"{path.relative_to(BACKEND_DIR)}:{node.lineno}: calls "
                    f"{node.func.id}() (route handler defined at line {defined_at}) "
                    f"with {supplied} of {total} arguments; dependency parameters "
                    f"{deps} would receive raw FastAPI marker objects. Declare the "
                    f"same dependencies on the caller and forward them explicitly."
                )

    assert not violations, "\n".join(violations)
