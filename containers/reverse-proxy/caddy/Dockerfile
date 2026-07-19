FROM golang:1.25.1-alpine AS builder

RUN apk add --no-cache \
    curl \
    jq \
    tar \
    ca-certificates

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "$ARCH" in \
        x86_64) ARCH="amd64";; \
        aarch64) ARCH="arm64";; \
    esac; \
    \
    VERSION=$(curl -fsSL \
      https://api.github.com/repos/caddyserver/xcaddy/releases/latest \
      | jq -r '.tag_name' | sed 's/^v//'); \
    \
    curl -fsSL \
    "https://github.com/caddyserver/xcaddy/releases/download/v${VERSION}/xcaddy_${VERSION}_linux_${ARCH}.tar.gz" \
    -o /tmp/xcaddy.tar.gz; \
    \
    tar -xzf /tmp/xcaddy.tar.gz -C /usr/local/bin; \
    chmod +x /usr/local/bin/xcaddy


RUN xcaddy build latest \
    --with github.com/caddy-dns/cloudflare \
    --output /usr/bin/caddy



FROM alpine:3.22

RUN apk add --no-cache \
    tini \
    ca-certificates

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN mkdir -p \
    /etc/caddy \
    /data \
    /config \
    /srv/hello

COPY Caddyfile /etc/caddy/Caddyfile
COPY hello /srv/hello

EXPOSE 80 443

ENTRYPOINT ["/sbin/tini","--"]

CMD ["/usr/bin/caddy", "run", "--config", "/etc/caddy/Caddyfile"]