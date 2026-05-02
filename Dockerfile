FROM python:3.11-slim
ENV PYTHONUNBUFFERED=1
ENV SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    libssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/searxng/searxng.git .

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

RUN printf '[botdetection.ip_limit]\nenabled = false\n[botdetection.ip_lists]\nenabled = false\n' \
    > /etc/searxng/limiter.toml

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir msgspec
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir --no-build-isolation -e .

# Freeze version so git is never needed at runtime
RUN python -c "from searx.version import VERSION_STRING, VERSION_TAG, DOCKER_TAG, GIT_URL, GIT_BRANCH; \
    content = f'VERSION_STRING=\"{VERSION_STRING}\"\nVERSION_TAG=\"{VERSION_TAG}\"\nDOCKER_TAG=\"{DOCKER_TAG}\"\nGIT_URL=\"{GIT_URL}\"\nGIT_BRANCH=\"{GIT_BRANCH}\"\n'; \
    open('/app/searx/version_frozen.py', 'w').write(content)"

EXPOSE 8080
CMD ["python", "-m", "searx.webapp"]
