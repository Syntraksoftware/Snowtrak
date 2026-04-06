"""
Architecture Guard Tests: Enforce domain layer separation rules.

Prevents api.py from importing forbidden modules (services, db.connection, models).
Ensures all cross-layer dependencies flow through ports.
"""

import ast
import sys
from pathlib import Path
from typing import Set

import pytest


DOMAINS_DIR = Path(__file__).parent.parent / "map-backend" / "domains"

# Forbidden import patterns in api.py
FORBIDDEN_IMPORTS = {
    "services",  # Catches: from services.*, import services
    "db.connection",  # Catches: from db.connection import*, import db.connection
    "models",  # Catches: from models.*, import models (internal domain models)
}

# Allowed imports in api.py
ALLOWED_MODULES = {
    "fastapi",
    "asyncpg",
    "shared",
    "logging",
    "typing",
    "datetime",
    "uuid",
    "functools",
    "dataclasses",
    # domain-local imports allowed:
    "ports",  # Must use ports for infra access
}


class ImportVisitor(ast.NodeVisitor):
    """Visitor to collect all imports from an AST."""

    def __init__(self):
        self.imports: Set[str] = set()
        self.from_imports: dict[str, Set[str]] = {}  # module -> {names}

    def visit_Import(self, node: ast.Import):
        """Handle: import module [as alias]"""
        for alias in node.names:
            module = alias.name.split(".")[0]  # Get top-level module
            self.imports.add(module)
        self.generic_visit(node)

    def visit_ImportFrom(self, node: ast.ImportFrom):
        """Handle: from module import name"""
        if node.module:
            module = node.module.split(".")[0]  # Get top-level module
            names = {alias.name for alias in node.names}
            self.from_imports.setdefault(module, set()).update(names)
            self.imports.add(module)
        self.generic_visit(node)


def get_api_files() -> list[Path]:
    """Find all api.py files in domains."""
    return sorted(DOMAINS_DIR.glob("*/api.py"))


def extract_imports(file_path: Path) -> tuple[Set[str], dict[str, Set[str]]]:
    """Parse Python file and extract all imports."""
    try:
        tree = ast.parse(file_path.read_text())
    except SyntaxError as e:
        pytest.fail(f"Syntax error in {file_path}: {e}")

    visitor = ImportVisitor()
    visitor.visit(tree)
    return visitor.imports, visitor.from_imports


def test_api_no_direct_service_imports():
    """api.py must not import from services directly."""
    api_files = get_api_files()
    assert api_files, "No api.py files found in domains"

    violations = []
    for api_file in api_files:
        imports, from_imports = extract_imports(api_file)

        for forbidden in ["services"]:
            if forbidden in imports:
                violations.append(
                    f"{api_file.relative_to(DOMAINS_DIR.parent.parent)}: "
                    f"imports '{forbidden}' (should use ports instead)"
                )
            if forbidden in from_imports:
                names = ", ".join(from_imports[forbidden])
                violations.append(
                    f"{api_file.relative_to(DOMAINS_DIR.parent.parent)}: "
                    f"from {forbidden} import {names} (should use ports instead)"
                )

    assert not violations, "\n".join(violations)


def test_api_no_direct_db_connection_imports():
    """api.py must not import db.connection directly."""
    api_files = get_api_files()
    assert api_files, "No api.py files found in domains"

    violations = []
    for api_file in api_files:
        imports, from_imports = extract_imports(api_file)

        if "db" in imports:
            # Check if it's specifically db.connection
            content = api_file.read_text()
            if "db.connection" in content or "from db.connection" in content or "import db.connection" in content:
                violations.append(
                    f"{api_file.relative_to(DOMAINS_DIR.parent.parent)}: "
                    f"imports db.connection directly (should use ports instead)"
                )

    assert not violations, "\n".join(violations)


def test_api_no_internal_model_imports():
    """api.py must not import from internal domain models."""
    api_files = get_api_files()
    assert api_files, "No api.py files found in domains"

    violations = []
    for api_file in api_files:
        imports, from_imports = extract_imports(api_file)

        # Check for relative imports of models
        content = api_file.read_text()
        lines = content.split("\n")

        for i, line in enumerate(lines, 1):
            # Detect: from .models import, from ..models import, etc
            if "from" in line and "models" in line and ("relative" in line or "." in line.split("from")[1]):
                violations.append(
                    f"{api_file.relative_to(DOMAINS_DIR.parent.parent)}:{i}: "
                    f"{line.strip()} (should use ports instead)"
                )

    assert not violations, "\n".join(violations)


def test_api_imports_from_ports():
    """Each api.py should import from its domain's ports."""
    api_files = get_api_files()
    assert api_files, "No api.py files found in domains"

    violations = []
    for api_file in api_files:
        imports, from_imports = extract_imports(api_file)

        # Check that ports is imported
        if "ports" not in imports and "ports" not in from_imports:
            violations.append(
                f"{api_file.relative_to(DOMAINS_DIR.parent.parent)}: "
                f"must import from 'ports' (missing ports import)"
            )

    assert not violations, "\n".join(violations)


def test_api_no_forbidden_module_combinations():
    """Comprehensive check: api.py must follow 3-layer rule."""
    api_files = get_api_files()
    assert api_files, "No api.py files found in domains"

    violations = []
    for api_file in api_files:
        content = api_file.read_text()
        domain_name = api_file.parent.name

        # Forbidden direct imports in api.py
        forbidden_patterns = [
            ("services.", "direct service import (use ports)"),
            ("db.connection", "direct db.connection import (use ports)"),
            (f"from .models import", "internal model import (use ports)"),
            (f"from ..models import", "parent model import (use ports)"),
        ]

        for pattern, reason in forbidden_patterns:
            if pattern in content:
                violations.append(
                    f"{api_file.relative_to(DOMAINS_DIR.parent.parent)}: "
                    f"contains '{pattern}' - {reason}"
                )

    assert not violations, "\n".join(violations)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
