#!/bin/bash

exec /usr/bin/caddy run \
    --config /etc/caddy/Caddyfile \
    --adapter caddyfile