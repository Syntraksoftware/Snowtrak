# syntax=docker/dockerfile:1.7
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY map-backend/requirements.txt ./requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir --upgrade "wheel>=0.46.2" "setuptools>=80.9.0" "jaraco.context>=6.1.0"

# Copy application code, shared package, and repo-level db helpers (asyncpg pool + Alembic tree)
COPY map-backend/ ./
COPY shared/ ./shared/
COPY db/ ./db/
COPY routers/ ./routers/

RUN useradd --create-home --shell /usr/sbin/nologin appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 5200

# Run the application
CMD ["python", "run.py"]