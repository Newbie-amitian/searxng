# SearXNG Dockerfile for Render.com (FULLY FIXED - NO ERRORS)
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

# Create COMPLETE settings file with ALL problematic engines disabled
RUN cat > /etc/searxng/settings.yml << 'EOF'
use_default_settings: true

general:
  instance_name: "SearXNG"
  debug: false
  enable_metrics: false
  privacypolicy_url: false
  contact_url: false

server:
  port: 8080
  bind_address: "0.0.0.0"
  secret_key: "env:SEARXNG_SECRET"
  limiter: false
  image_proxy: true
  http_protocol_version: "1.1"

search:
  safe_search: 0
  default_lang: "en"
  formats:
    - html
    - json

outgoing:
  request_timeout: 10.0
  max_request_timeout: 15.0
  pool_connections: 100
  pool_maxsize: 20

# Disable ALL problematic engines
engines:
  - name: ahmia
    engine: ahmia
    disabled: true
  - name: torch
    engine: torch  
    disabled: true
  - name: wikidata
    engine: wikidata
    disabled: true
  
# Enable working engines explicitly
  - name: google
    engine: google
    shortcut: g
    disabled: false
  - name: bing
    engine: bing
    shortcut: b
    disabled: false
  - name: duckduckgo
    engine: duckduckgo
    shortcut: ddg
    disabled: false
  - name: startpage
    engine: startpage
    shortcut: sp
    disabled: false
  - name: wikipedia
    engine: wikipedia
    shortcut: wp
    disabled: false
  - name: yahoo
    engine: yahoo
    shortcut: y
    disabled: false
  - name: brave
    engine: brave
    shortcut: br
    disabled: false
EOF

# Upgrade pip first
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install msgspec BEFORE anything else (required by setup.py)
RUN pip install --no-cache-dir msgspec

# Install all requirements
RUN pip install --no-cache-dir -r requirements.txt

# Install SearXNG without build isolation
RUN pip install --no-cache-dir --no-build-isolation -e .

EXPOSE 8080

# Health check for Render
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/', timeout=5)" || exit 1

CMD ["python", "-m", "searx.webapp"]
