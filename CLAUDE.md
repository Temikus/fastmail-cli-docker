# fastmail-cli-docker

Docker image packaging the [fastmail-cli](https://github.com/radiosilence/fastmail-cli) Rust MCP server with [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) for SSE transport support. Published to `ghcr.io/temikus/fastmail-cli-mcp`.

## Build & Push

Uses `just` for task automation:

- `just build` — Build Docker image (linux/amd64)
- `just push` — Push to ghcr.io

## Architecture

Three-stage Docker build:

1. **fastmail-cli-build** — Compiles the Rust binary from source (`rust:1-alpine`)
2. **mcp-proxy-build** — Builds mcp-proxy Python venv from vendored source (UV + Python 3.13)
3. **Final image** — Minimal Alpine with the binary, Python venv, catatonit, and entrypoint

Transport modes via `MCP_TRANSPORT` env var:
- `stdio` — Runs `fastmail-cli mcp` directly
- `sse` (default) — Wraps behind mcp-proxy on `MCP_PORT` (default 3000)

## Environment Variables

Required:
- `FASTMAIL_API_TOKEN` — Fastmail API token

Optional:
- `FASTMAIL_USERNAME` — For CardDAV contacts
- `FASTMAIL_APP_PASSWORD` — For CardDAV contacts
- `MCP_TRANSPORT` — `sse` (default) or `stdio`
- `MCP_PORT` — SSE listen port (default 3000)
- `MCP_HOST` — SSE listen address (default 0.0.0.0)
- `LOG_LEVEL` — `debug`, `info` (default), `warn`, `error`

## Key Details

- mcp-proxy is a vendored copy (has its own .git) from https://github.com/sparfenyuk/mcp-proxy
- catatonit used as PID 1 in SSE mode for signal handling
- fastmail-cli is statically linked against musl (Alpine), no glibc-compat conflicts
- The Rust binary runs `fastmail-cli mcp` which starts an MCP server on stdio
- Default transport is SSE (unlike jmap-mcp-docker which defaults to stdio)
