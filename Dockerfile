# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG TARGETARCH
ARG NODE_VERSION=24.18.0
ARG BUN_INSTALL=/opt/bun
ARG UV_INSTALL_DIR=/opt/uv

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUN_INSTALL=${BUN_INSTALL} \
    UV_INSTALL_DIR=${UV_INSTALL_DIR} \
    UV_NO_MODIFY_PATH=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    PATH=${BUN_INSTALL}/bin:${UV_INSTALL_DIR}:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base development tools, including JSON, fuzzy-search, and GitHub CLIs.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fzf \
        gh \
        git \
        gnupg \
        jq \
        less \
        locales \
        python-is-python3 \
        python3 \
        python3-pip \
        python3-venv \
        tmux \
        unzip \
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
    && tmux -V

WORKDIR /workspace
USER root
CMD ["bash"]
