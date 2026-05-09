#!/bin/sh
set -e

log() { echo "[entrypoint] $*" >&2; }

if [ -z "$FASTMAIL_API_TOKEN" ]; then
    log "ERROR: FASTMAIL_API_TOKEN environment variable is required"
    exit 1
fi

log "fastmail-cli v${FASTMAIL_CLI_VERSION} starting"
log "Transport: ${MCP_TRANSPORT}"

if [ -n "$FASTMAIL_USERNAME" ]; then
    log "CardDAV contacts: enabled (user: ${FASTMAIL_USERNAME})"
fi

FASTMAIL_CMD="fastmail-cli mcp"

case "${MCP_TRANSPORT}" in
    stdio)
        log "Launching fastmail-cli (stdio mode)"
        exec $FASTMAIL_CMD "$@"
        ;;
    sse)
        log "Launching mcp-proxy on ${MCP_HOST}:${MCP_PORT} (SSE mode)"
        exec catatonit -- mcp-proxy \
            --port="${MCP_PORT}" \
            --host="${MCP_HOST}" \
            --pass-environment \
            -- $FASTMAIL_CMD "$@"
        ;;
    *)
        log "ERROR: Unknown MCP_TRANSPORT value '${MCP_TRANSPORT}'. Use 'stdio' or 'sse'."
        exit 1
        ;;
esac
