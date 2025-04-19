FROM debian:bookworm-slim AS base

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      git-lfs \
      unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

FROM base AS downloader

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
      curl \
      jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /download

ARG FLUTTER_VERSION

RUN RELEASE_VERSION=$(curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json \
    | jq -r --arg version "$FLUTTER_VERSION" '[.releases[] | select(.channel == "stable") | select(.version | startswith($version))] | sort_by(.release_date) | last | .version') \
    && echo "Downloading $RELEASE_VERSION as latest $FLUTTER_VERSION release" \
    && git clone --depth=1 --branch "$RELEASE_VERSION" https://github.com/flutter/flutter.git \
    && ./flutter/bin/flutter --version

FROM base

ARG APP_VERSION=dev
LABEL org.opencontainers.image.description="Container image with Flutter pre-installed."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/BlindfoldedSurgery/container-flutter"
LABEL org.opencontainers.image.url="https://github.com/BlindfoldedSurgery/container-flutter"
LABEL org.opencontainers.image.version=$APP_VERSION

RUN groupadd --system --gid 500 app
RUN useradd --system --uid 500 --gid app --create-home --home-dir /app -s /bin/bash app

RUN git config --system --add safe.directory /opt/flutter
COPY --from=downloader --chown=app /download/flutter /opt/flutter
ENV PATH=${PATH}:/opt/flutter/bin

USER app
WORKDIR /app

RUN flutter doctor --suppress-analytics
