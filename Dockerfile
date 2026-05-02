# SearXNG Dockerfile for Render.com (FINAL FIX)
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    libssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone SearXNG
RUN git clone --depth 1 https://github.com/searxng/searxng.git . && \
    rm -rf .git

# Upgrade pip first
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install msgspec BEFORE anything else (required by setup.py)
RUN pip install --no-cache-dir msgspec

# Install all requirements
RUN pip install --no-cache-dir -r requirements.txt

# Install SearXNG without build isolation (uses already installed packages)
RUN pip install --no-cache-dir --no-build-isolation -e .

# Create settings directory
RUN mkdir -p /etc/searxng

# Create settings file with JSON API enabled
RUN printf 'use_default_settings: true\n\
general:\n\
  instance_name: "SearXNG"\n\
  debug: false\n\
server:\n\
  port: 8080\n\
  bind_address: "0.0.0.0"\n\
  secret_key: "env:SEARXNG_SECRET"\n\
  limiter: false\n\
  image_proxy: true\n\
search:\n\
  safe_search: 0\n\
  default_lang: "en"\n\
  formats:\n\
    - html\n\
    - json\n\
outgoing:\n\
  request_timeout: 10.0\n\
' > /etc/searxng/settings.yml

EXPOSE 8080

CMD ["python", "-m", "searx.webapp"]
