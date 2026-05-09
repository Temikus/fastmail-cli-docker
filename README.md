# fastmail-cli-docker

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Docker image packaging [fastmail-cli](https://github.com/radiosilence/fastmail-cli) (a Rust-based Fastmail JMAP MCP server) with [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) for SSE transport support.

Published to `ghcr.io/temikus/fastmail-cli-mcp`.

## Quick Start

```bash
docker run -d \
  -p 3000:3000 \
  -e FASTMAIL_API_TOKEN=fmu1-... \
  ghcr.io/temikus/fastmail-cli-mcp
```

The MCP server is now accessible via SSE at `http://localhost:3000/sse`.

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `FASTMAIL_API_TOKEN` | Yes | — | Fastmail API token (generate at Fastmail Settings > Privacy & Security > Integrations > API tokens) |
| `FASTMAIL_USERNAME` | No | — | Fastmail username (for CardDAV contacts) |
| `FASTMAIL_APP_PASSWORD` | No | — | App password (for CardDAV contacts) |
| `MCP_TRANSPORT` | No | `sse` | Transport mode: `sse` or `stdio` |
| `MCP_PORT` | No | `3000` | SSE server listen port |
| `MCP_HOST` | No | `0.0.0.0` | SSE server listen address |
| `LOG_LEVEL` | No | `info` | Log level: `debug`, `info`, `warn`, `error` |

## Architecture

```
LLM Client <--SSE--> mcp-proxy <--stdio--> fastmail-cli mcp
```

The container uses [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) to bridge between SSE (network-accessible) and stdio (what fastmail-cli speaks natively). [catatonit](https://github.com/openSUSE/catatonit) serves as PID 1 for proper signal handling.

### Build Stages

1. **fastmail-cli-build** — Compiles the Rust binary from source using `rust:1-alpine`
2. **mcp-proxy-build** — Installs the Python mcp-proxy package using UV
3. **Final image** — Minimal Alpine with just the binary, Python venv, and entrypoint

## Building

Requires [just](https://github.com/casey/just) and Docker.

```bash
# Vendor mcp-proxy (first time only)
git clone https://github.com/sparfenyuk/mcp-proxy.git mcp-proxy

# Build
just build

# Push to ghcr.io
just push
```

## License

Apache-2.0
