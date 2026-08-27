# syntax=docker/dockerfile:1.7
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY activity-backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir --upgrade "pip>=26.1.2" "wheel>=0.46.2" "setuptools>=80.9.0" "jaraco.context>=6.1.0"

# Remove pip from the runtime image. Trivy reads pip/_vendor/vendor.txt and
# reports pip's own vendored msgpack and setuptools as installed packages, and
# upgrading setuptools does not touch them -- the real one in site-packages is
# already current. Nothing in this image runs pip after the build, so deleting
# it removes the code rather than suppressing the finding.
RUN python -m pip uninstall -y pip

COPY activity-backend/ ./
COPY shared/ ./shared/

RUN useradd --create-home --shell /usr/sbin/nologin appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5100

CMD ["python", "run.py"]