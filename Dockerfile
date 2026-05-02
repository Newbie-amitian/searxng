FROM python:3.11-slim
ENV PYTHONUNBUFFERED=1
ENV SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone but KEEP .git so version detection works
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && git clone --depth 1 https://github.com/searxng/searxng.git . \
    && apt-get purge -y git \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/searxng

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
engines:\n\
  - name: wikidata\n\
    disabled: true\n\
  - name: ahmia\n\
    disabled: true\n\
  - name: torch\n\
    disabled: true\n\
' > /etc/searxng/settings.yml

# Create empty limiter.toml to silence the warning
RUN printf '[botdetection.ip_limit]\nenabled = false\n[botdetection.ip_lists]\nenabled = false\n' \
    > /etc/searxng/limiter.toml

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir msgspec
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir --no-build-isolation -e .

EXPOSE 8080
CMD ["python", "-m", "searx.webapp"]
