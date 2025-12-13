#!/bin/bash

# Community Backend Startup Script (FastAPI)

echo "🚀 Starting Syntrak Community API..."

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

# Start FastAPI server
echo "⚡ Starting FastAPI server..."
uvicorn main:app --host 0.0.0.0 --port 5001 --reload
