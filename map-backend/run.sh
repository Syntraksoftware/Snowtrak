#!/bin/bash

# Map Backend Run Script
# Starts the FastAPI server with uvicorn

echo "Starting Map Backend..."

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run with uvicorn
uvicorn main:app --host 127.0.0.1 --port 5200 --reload
