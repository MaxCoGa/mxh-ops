FROM alpine:3.22

RUN apk add --no-cache \
    curl \
    jq \
    ca-certificates \
    bash

COPY ddns.sh /usr/local/bin/ddns.sh

RUN chmod +x /usr/local/bin/ddns.sh

CMD ["/usr/local/bin/ddns.sh"]