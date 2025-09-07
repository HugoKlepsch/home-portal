# Build stage
ARG CADDY_VERSION=2.10.2
FROM caddy:${CADDY_VERSION}-builder-alpine AS builder

ARG LINODE_PLUGIN_FORK=github.com/caddy-dns/linode

# Build Caddy with the Linode DNS module
RUN GOTOOLCHAIN=auto xcaddy build \
    --with ${LINODE_PLUGIN_FORK} \
    --with github.com/mholt/caddy-hitcounter

# Final stage
FROM caddy:${CADDY_VERSION}-alpine

# Copy the custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
