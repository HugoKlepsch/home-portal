# Build stage
ARG CADDY_VERSION
FROM caddy:${CADDY_VERSION}-builder-alpine AS builder

ARG LINODE_PLUGIN_FORK

# Build Caddy with the Cloudflare DNS module
RUN xcaddy build --with ${LINODE_PLUGIN_FORK}

# Final stage
FROM caddy:${CADDY_VERSION}-alpine

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
