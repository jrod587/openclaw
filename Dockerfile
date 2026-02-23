FROM node:22-bookworm@sha256:cd7bcd2e7a1e6f72052feb023c7f6b722205d3fcab7bbcbd2d1bfdab10b1e935

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app
RUN chown node:node /app

# Install gog (Google Workspace CLI) for Calendar Pareto management
RUN curl -L "https://github.com/steipete/gogcli/releases/download/v0.11.0/gogcli_0.11.0_linux_amd64.tar.gz" -o gog.tar.gz && \
  tar -xzf gog.tar.gz gog && \
  mv gog /usr/local/bin/gog && \
  rm gog.tar.gz

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 python3-venv $OPENCLAW_DOCKER_APT_PACKAGES && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*;


COPY --chown=node:node package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY --chown=node:node ui/package.json ./ui/package.json
COPY --chown=node:node patches ./patches
COPY --chown=node:node scripts ./scripts

USER node
RUN pnpm install --frozen-lockfile

# Optionally install Chromium and Xvfb for browser automation.
# Build with: docker build --build-arg OPENCLAW_INSTALL_BROWSER=1 ...
# Adds ~300MB but eliminates the 60-90s Playwright install on every container start.
# Must run after pnpm install so playwright-core is available in node_modules.
USER root
ARG OPENCLAW_INSTALL_BROWSER=""
RUN if [ -n "$OPENCLAW_INSTALL_BROWSER" ]; then \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
  mkdir -p /home/node/.cache/ms-playwright && \
  PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
  node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
  chown -R node:node /home/node/.cache/ms-playwright && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
  fi

# Install gcloud CLI (required for Gmail Pub/Sub setup)
USER root
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  apt-get update && apt-get install -y google-cloud-sdk && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

USER node
COPY --chown=node:node . .
RUN pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Security hardening: Ensure the node user owns the state directory
# This fixes the EACCES errors found in Sliplane logs
USER root
RUN mkdir -p /home/node/.openclaw && chown -R node:node /home/node/.openclaw
USER node

# Ensure OpenClaw uses the original state directory even when running as root
ENV OPENCLAW_STATE_DIR=/home/node/.openclaw

# Expose port so Sliplane automatically routes health checks correctly
EXPOSE 8080

# Start gateway server with default config.
# Binds to loopback (127.0.0.1) by default for security.
#
# For container platforms requiring external health checks:
#   1. Set OPENCLAW_GATEWAY_TOKEN or OPENCLAW_GATEWAY_PASSWORD env var
#   2. Override CMD: ["node","openclaw.mjs","gateway","--allow-unconfigured","--bind","lan"]
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan", "--port", "8080"]
