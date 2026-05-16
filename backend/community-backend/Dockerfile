# syntax=docker/dockerfile:1.7
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY community-backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir --upgrade "wheel>=0.46.2" "setuptools>=80.9.0" "jaraco.context>=6.1.0"

COPY community-backend/ ./
COPY shared/ ./shared/

RUN useradd --create-home --shell /usr/sbin/nologin appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5001

CMD ["python", "run.py"]