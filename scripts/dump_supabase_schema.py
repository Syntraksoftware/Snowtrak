#!/usr/bin/env python3
"""Record the live Supabase schema into docs/database_schema.md.

Read-only by construction: it asks PostgREST to describe itself and writes a
document. It issues no DDL and cannot create, alter or drop anything. The
schema is kept in git as a record of what exists, not as a script that could
rebuild it -- see docs/database_changes.md.

    python scripts/dump_supabase_schema.py

Credentials come from backend/main-backend/.env (SUPABASE_URL and
SUPABASE_SERVICE_ROLE_KEY); nothing is printed or written to the document.
"""

from __future__ import annotations

import json
import re
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENV = ROOT / "backend" / "main-backend" / ".env"
OUT = ROOT / "docs" / "database_schema.md"

# PostGIS ships these; they are not ours and say nothing about the application.
POSTGIS_INTERNALS = {"spatial_ref_sys", "geometry_columns", "geography_columns"}
# Created by backend/db/migrations/versions/. Everything else in public was
# made by hand in the Supabase dashboard.
ALEMBIC_OWNED = {"map_cache_entries", "elevation_samples"}
ALEMBIC_BOOKKEEPING = {"alembic_version"}


def load_env() -> dict[str, str]:
    env = {}
    for line in ENV.read_text().splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip()
    return env


def fetch_spec(env: dict[str, str]) -> dict:
    key = env["SUPABASE_SERVICE_ROLE_KEY"]
    request = urllib.request.Request(
        env["SUPABASE_URL"].rstrip("/") + "/rest/v1/",
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Accept": "application/openapi+json",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def describe_key(description: str) -> str:
    if "<pk/>" in description:
        return "PK"
    match = re.search(r"<fk table='([^']+)' column='([^']+)'/>", description)
    return f"FK → `{match.group(1)}.{match.group(2)}`" if match else ""


def render_table(name: str, definition: dict) -> str:
    required = set(definition.get("required", []))
    rows = ["| Column | Type | Null | Default | Key |", "|---|---|---|---|---|"]
    for column, spec in definition.get("properties", {}).items():
        default = spec.get("default", "")
        if isinstance(default, bool):  # JSON True/False, not SQL
            default = str(default).lower()
        rows.append(
            f"| `{column}` "
            f"| {spec.get('format', spec.get('type', '?'))} "
            f"| {'no' if column in required else 'yes'} "
            f"| {f'`{default}`' if default != '' else ''} "
            f"| {describe_key(spec.get('description', ''))} |"
        )
    return f"### `{name}`\n\n" + "\n".join(rows) + "\n"


def main() -> None:
    definitions = fetch_spec(load_env()).get("definitions", {})
    groups: dict[str, list[str]] = {"app": [], "alembic": [], "internal": []}
    for name in sorted(definitions):
        if name in POSTGIS_INTERNALS or name in ALEMBIC_BOOKKEEPING:
            groups["internal"].append(name)
        elif name in ALEMBIC_OWNED:
            groups["alembic"].append(name)
        else:
            groups["app"].append(name)

    out = [
        "# Supabase schema",
        "",
        f"What the live database contains, as of {date.today().isoformat()}.",
        "",
        "**This is a record, not a migration.** It is not runnable and must never",
        "be treated as something to apply. Changing the database means changing it",
        "in Supabase and regenerating this file -- in the order described in",
        "[database_changes.md](database_changes.md).",
        "",
        "Regenerate with `python scripts/dump_supabase_schema.py`, which reads the",
        "schema over PostgREST and writes this file. Commit the result.",
        "",
        "Two blind spots, both inherent to reading the schema through PostgREST:",
        "the `map_trail` schema is not exposed, so the five tables Alembic keeps",
        "there do not appear below; and check constraints, indexes, triggers and",
        "row-level-security policies are invisible to it.",
        "",
        "## Application tables",
        "",
        "Created by hand in the Supabase dashboard. Nothing in this repository",
        "defines them and no test asserts their shape.",
        "",
    ]
    out += [render_table(n, definitions[n]) for n in groups["app"]]
    out += [
        "## Map tables",
        "",
        "Owned by `backend/db/migrations/versions/`. Change these with an Alembic",
        "revision, not in the dashboard.",
        "",
    ]
    out += [render_table(n, definitions[n]) for n in groups["alembic"]]
    out += [
        "## Not ours",
        "",
        "PostGIS internals and Alembic's own bookkeeping: "
        + ", ".join(f"`{n}`" for n in groups["internal"])
        + ".",
        "",
    ]

    OUT.write_text("\n".join(out))
    print(f"wrote {OUT.relative_to(ROOT)}: {len(groups['app'])} application tables, "
          f"{len(groups['alembic'])} map tables")


if __name__ == "__main__":
    main()
