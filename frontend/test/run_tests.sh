#!/bin/bash
# Script to run all Flutter tests with coverage

set -e

echo "🧪 Running Flutter tests..."

cd "$(dirname "$0")/.."

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run tests with coverage
echo "🔍 Running tests with coverage..."
flutter test --coverage

# Check if lcov is installed
if command -v genhtml &> /dev/null; then
    echo "📊 Generating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    echo "✅ Coverage report generated at: coverage/html/index.html"
    echo "🌐 Open with: open coverage/html/index.html"
else
    echo "ℹ️  Install lcov to generate HTML coverage: brew install lcov"
fi

echo "✅ Tests completed!"


