# Ubuntu Agent Image

This repository builds an Ubuntu-based development image for agents and publishes it to GitHub Container Registry and Docker Hub with GitHub Actions.

## Included tools

- Python
- .NET SDK
- Node.js
- Bun
- uv
- `jq` for JSON processing
- `fzf` for interactive fuzzy search
- GitHub CLI (`gh`)
- ripgrep (`rg`) for fast recursive search
- tmux

## What gets published

On pushes to `main`, tags that start with `v`, or a manual workflow run, GitHub Actions builds the image from `Dockerfile`.

- Pull requests: build only, no push
- `main`: push the `latest` image to GitHub Container Registry and Docker Hub
- `v*` tags: push versioned tags to GitHub Container Registry and Docker Hub

The image names are:

```text
ghcr.io/<owner>/ubuntu-agent-image
<dockerhub-username>/ubuntu-agent-image
```

## First-time setup

1. Create the `ubuntu-agent-image` repository in Docker Hub under your account.
2. Add the required GitHub Actions secrets below.
3. Push to the `main` branch or run the workflow manually from the Actions tab.
4. Find the GitHub image in the repository's Packages section and the Docker image in Docker Hub.

### Required GitHub Actions secrets

Add these repository secrets under **Settings → Secrets and variables → Actions**:

- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub access token (recommended) or password

The workflow uses these secrets only for non-pull-request builds. Pull requests are build-only and do not publish images.

## Build locally

```bash
docker build -t ubuntu-agent-image .
```

## Use the image

```bash
docker pull ghcr.io/<owner>/ubuntu-agent-image:latest
# or
docker pull <dockerhub-username>/ubuntu-agent-image:latest

docker run -it --rm <dockerhub-username>/ubuntu-agent-image:latest

# Runs as root by default

# Verify the additional command-line tools
docker run --rm <dockerhub-username>/ubuntu-agent-image:latest jq --version
docker run --rm <dockerhub-username>/ubuntu-agent-image:latest fzf --version
docker run --rm <dockerhub-username>/ubuntu-agent-image:latest gh --version
docker run --rm <dockerhub-username>/ubuntu-agent-image:latest rg --version
```

## Customize versions

The Dockerfile currently pins Node.js with:

```dockerfile
ARG NODE_VERSION=24.18.0
```

You can change that value any time. Bun and uv are installed with their official install scripts, and .NET comes from Ubuntu's package feed.

## Notes

- Container dijalankan sebagai `root` user.
- The workflow is currently set to build `linux/amd64`.
- The workflow publishes to both GitHub Container Registry and Docker Hub.
