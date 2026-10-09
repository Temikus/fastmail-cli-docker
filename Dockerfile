# Stage 1: Build fastmail-cli from source
FROM rust:1-alpine AS fastmail-cli-build

ARG FASTMAIL_CLI_VERSION=2.2.2

RUN apk add --no-cache musl-dev openssl-dev openssl-libs-static git cmake make perl clang-dev curl

WORKDIR /build

RUN git clone --depth 1 --branch v${FASTMAIL_CLI_VERSION} \
    https://github.com/radiosilence/fastmail-cli.git . || \
    git clone --depth 1 --branch ${FASTMAIL_CLI_VERSION} \
    https://github.com/radiosilence/fastmail-cli.git .

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/build/target \
    cargo build --release && \
    cp target/release/fastmail-cli /usr/local/bin/fastmail-cli

# Stage 2: Build mcp-proxy
FROM ghcr.io/astral-sh/uv:python3.13-alpine AS mcp-proxy-build

WORKDIR /app

ARG UV_COMPILE_BYTECODE=1
ARG UV_LINK_MODE=copy

# Install dependencies first for layer caching
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=mcp-proxy/uv.lock,target=uv.lock \
    --mount=type=bind,source=mcp-proxy/pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Copy mcp-proxy source and install
COPY mcp-proxy/ /app/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Fix venv python symlinks to be self-contained (resolve to /app/.venv/bin/python3.13)
RUN cp /usr/local/bin/python3.13 /app/.venv/bin/python3.13 && \
    cd /app/.venv/bin && \
    rm -f python python3 && \
    ln -s python3.13 python3 && \
    ln -s python3 python

RUN apk add --update --no-cache catatonit

# Stage 3: Final image
FROM alpine:3.24

ARG FASTMAIL_CLI_VERSION=2.2.2
ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="temikus" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.title="fastmail-cli-mcp" \
    org.opencontainers.image.description="Fastmail CLI MCP Server - Model Context Protocol server for Fastmail email interaction via SSE" \
    org.opencontainers.image.version=$FASTMAIL_CLI_VERSION \
    org.opencontainers.image.url="https://github.com/temikus/fastmail-cli-docker" \
    org.opencontainers.image.source="https://github.com/temikus/fastmail-cli-docker" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.vendor="temikus" \
    org.opencontainers.image.licenses="Apache-2.0"

# Copy fastmail-cli binary
COPY --from=fastmail-cli-build /usr/local/bin/fastmail-cli /usr/local/bin/fastmail-cli

# Copy Python runtime from build stage
COPY --from=mcp-proxy-build /usr/local/lib/libpython3.13.so.1.0 /usr/local/lib/
COPY --from=mcp-proxy-build /usr/local/lib/python3.13 /usr/local/lib/python3.13

# Copy mcp-proxy virtualenv and catatonit from build stage
COPY --from=mcp-proxy-build /app/.venv /app/.venv
COPY --from=mcp-proxy-build /usr/bin/catatonit /usr/bin/catatonit

ENV PATH="/app/.venv/bin:$PATH"

# MCP transport configuration
ENV MCP_TRANSPORT=sse
ENV MCP_PORT=3000
ENV MCP_HOST=0.0.0.0

# Logging
ENV LOG_LEVEL=info

EXPOSE 3000

RUN addgroup -S mcp && adduser -S mcp -G mcp

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER mcp

ENV FASTMAIL_CLI_VERSION=${FASTMAIL_CLI_VERSION}

ENTRYPOINT ["docker-entrypoint.sh"]
