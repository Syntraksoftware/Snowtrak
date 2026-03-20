#!/bin/bash

# Community Backend Startup Script (FastAPI)

echo "🚀 Starting Syntrak Community API..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Install dependencies (use venv's pip so we don't hit system/externally-managed)
echo "📥 Installing dependencies..."
venv/bin/pip install -r requirements.txt

# Start FastAPI server (use venv's uvicorn)
echo "⚡ Starting FastAPI server..."
exec venv/bin/uvicorn main:app --host 0.0.0.0 --port 5001 --reload
