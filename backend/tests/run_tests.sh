#!/bin/bash
# Script to run all backend tests with coverage

set -e

echo "🧪 Running backend tests..."

cd "$(dirname "$0")/.."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip first
echo "⬆️  Upgrading pip..."
pip install --upgrade pip --quiet

# Install dependencies
echo "📦 Installing dependencies..."
pip install -q -r requirements.txt -r requirements-test.txt

# Run tests with coverage
echo "🔍 Running tests with coverage..."
pytest

# Check coverage threshold
echo "📊 Coverage report generated in htmlcov/index.html"
echo "🌐 Open with: open htmlcov/index.html"

echo "✅ Tests completed!"

