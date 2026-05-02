# SearXNG Dockerfile for Render.com (PRODUCTION READY)
# No errors, clean startup
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

# Clone SearXNG - KEEP .git for version detection
RUN git clone --depth 1 https://github.com/searxng/searxng.git .

# Create settings directory
RUN mkdir -p /etc/searxng

# Create settings file - disable problematic engines
RUN printf 'use_default_settings: true\n\
general:\n\
  instance_name: "SearXNG"\n\
  debug: false\n\
  enable_metrics: false\n\
server:\n\
  port: 8080\n\
  bind_address: "0.0.0.0"\n\
  secret_key: "env:SEARXNG_SECRET"\n\
  limiter: false\n\
  image_proxy: true\n\
  method: "GET"\n\
search:\n\
  safe_search: 0\n\
  default_lang: "en"\n\
  formats:\n\
    - html\n\
    - json\n\
outgoing:\n\
  request_timeout: 10.0\n\
  max_request_timeout: 15.0\n\
engines:\n\
  - name: wikidata\n\
    engine: wikidata\n\
    disabled: true\n\
  - name: ahmia\n\
    engine: ahmia\n\
    disabled: true\n\
  - name: torch\n\
    engine: torch\n\
    disabled: true\n\
' > /etc/searxng/settings.yml

# Create limiter.toml to silence warnings
RUN printf '[botdetection.ip_limit]\n\
enabled = false\n\
\n\
[botdetection.link_token]\n\
enabled = false\n\
\n\
[botdetection.ip_lists]\n\
enabled = false\n\
' > /etc/searxng/limiter.toml

# Upgrade pip first
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install msgspec BEFORE anything else (required by setup.py)
RUN pip install --no-cache-dir msgspec

# Install all requirements
RUN pip install --no-cache-dir -r requirements.txt

# Install SearXNG without build isolation
RUN pip install --no-cache-dir --no-build-isolation -e .

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/')" || exit 1

CMD ["python", "-m", "searx.webapp"]
