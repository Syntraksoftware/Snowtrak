#!/bin/bash

# Community Backend Startup Script

echo "🚀 Starting Community Backend..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found! Copying from .env.example..."
    cp .env.example .env
    echo "⚙️  Please edit .env with your credentials before running again."
    exit 1
fi

# Run the app
echo "✅ Starting Flask server..."
python app.py
