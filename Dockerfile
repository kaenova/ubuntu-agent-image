# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG TARGETARCH
ARG NODE_VERSION=24.18.0
ARG BUN_INSTALL=/opt/bun
ARG UV_INSTALL_DIR=/opt/uv
ARG AGENT_UID=10001
ARG AGENT_GID=10001

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUN_INSTALL=${BUN_INSTALL} \
    UV_INSTALL_DIR=${UV_INSTALL_DIR} \
    UV_NO_MODIFY_PATH=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    HOME=/home/agent \
    NPM_CONFIG_PREFIX=/home/agent/.local \
    UV_CACHE_DIR=/home/agent/.cache/uv \
    PATH=/home/agent/.local/bin:${BUN_INSTALL}/bin:${UV_INSTALL_DIR}:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base development tools, including JSON, fuzzy-search, and GitHub CLIs.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        file \
        fonts-dejavu \
        fonts-liberation \
        fonts-noto-core \
        fzf \
        gh \
        git \
        gnupg \
        jq \
        less \
        libmagic1 \
        libreoffice-impress \
        locales \
        make \
        nano \
        openssh-client \
        pandoc \
        pdfgrep \
        poppler-utils \
        python-is-python3 \
        python3 \
        python3-pip \
        python3-venv \
        qpdf \
        ripgrep \
        rsync \
        shellcheck \
        sqlite3 \
        tmux \
        tree \
        unzip \
        vim-tiny \
        wget \
        xz-utils \
        zip \
        dotnet-sdk-10.0 \
    && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
        amd64) NODE_ARCH='x64' ;; \
        arm64) NODE_ARCH='arm64' ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
    && tar -xJf "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"

RUN mkdir -p "${BUN_INSTALL}" \
    && curl -fsSL https://bun.sh/install | bash \
    && ln -sf "${BUN_INSTALL}/bin/bun" /usr/local/bin/bun

RUN mkdir -p "${UV_INSTALL_DIR}" \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -sf "${UV_INSTALL_DIR}/uv" /usr/local/bin/uv \
    && if [ -f "${UV_INSTALL_DIR}/uvx" ]; then ln -sf "${UV_INSTALL_DIR}/uvx" /usr/local/bin/uvx; fi

# Create a dedicated non-root runtime user. /home/data is created with the
# agent UID and group permissions so the built-in workspace is accessible to it.
# When /home/data is bind-mounted, host-side ownership and permissions still take
# precedence over this image-layer ownership.
RUN if getent passwd "${AGENT_UID}" >/dev/null; then \
        echo "AGENT_UID=${AGENT_UID} is already assigned in the base image" >&2; \
        exit 1; \
    fi \
    && if getent group agent >/dev/null; then \
        groupmod --gid "${AGENT_GID}" agent; \
    elif getent group "${AGENT_GID}" >/dev/null; then \
        groupadd agent; \
    else \
        groupadd --gid "${AGENT_GID}" agent; \
    fi \
    && useradd \
        --uid "${AGENT_UID}" \
        --gid agent \
        --create-home \
        --shell /bin/bash \
        agent \
    && mkdir -p \
        /home/agent/.local/bin \
        /home/agent/.cache/uv \
        /home/agent/.config \
        /home/agent/.npm \
        /home/agent/.local/share \
    && install -d \
        -o "${AGENT_UID}" \
        -g agent \
        -m 0770 \
        /home/data \
    && chown -R agent:agent /home/agent

RUN python --version \
    && python3 --version \
    && pip3 --version \
    && node --version \
    && npm --version \
    && bun --version \
    && uv --version \
    && dotnet --info \
    && jq --version \
    && fzf --version \
    && gh --version \
    && rg --version \
    && tmux -V \
    && pandoc --version \
    && soffice --version \
    && pdftotext -v \
    && qpdf --version \
    && shellcheck --version \
    && sqlite3 --version

WORKDIR /home/data
USER root
CMD ["bash"]
