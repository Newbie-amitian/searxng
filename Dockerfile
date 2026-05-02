# SearXNG Dockerfile for Render.com
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    openssl \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/searxng/searxng.git . && \
    rm -rf .git

RUN pip install --no-cache-dir -e .

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
' > /etc/searxng/settings.yml

EXPOSE 8080

CMD ["python", "-m", "searx.webapp"]
