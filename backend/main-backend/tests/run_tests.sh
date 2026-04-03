#!/bin/bash
# Run main-backend tests using the shared repo-root virtual environment.

set -e

echo "🧪 Running main-backend tests..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_BACKEND="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MAIN_BACKEND/../.." && pwd)"
VENV_DIR="$REPO_ROOT/.venv"
ACTIVATE="$VENV_DIR/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
  echo "❌ No venv at $VENV_DIR"
  echo "   From repo root: python3 -m venv .venv && ./.venv/bin/pip install -r backend/requirements.txt"
  exit 1
fi

cd "$MAIN_BACKEND"

echo "🔌 Using $VENV_DIR"
# shellcheck source=/dev/null
source "$ACTIVATE"

echo "⬆️  Upgrading pip..."
pip install --upgrade pip --quiet

echo "📦 Installing dependencies..."
pip install -q -r requirements.txt
if [ -f requirements-test.txt ]; then
  pip install -q -r requirements-test.txt
fi

echo "🔍 Running tests with coverage..."
pytest

echo "📊 Coverage report generated in htmlcov/index.html"
echo "🌐 Open with: open htmlcov/index.html"
echo "✅ Tests completed!"
