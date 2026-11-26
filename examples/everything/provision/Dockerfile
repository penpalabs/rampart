FROM alpine:3.20
RUN apk add --no-cache bash curl jq coreutils
WORKDIR /provision
COPY provision.sh ./
COPY sections/ ./sections/
RUN chmod +x provision.sh
# Unprivileged user. /shared is created here owned by it, so the empty named
# volume mounted there inherits that ownership on first `docker compose up`.
RUN adduser -D -H -u 10001 provision && mkdir -p /shared && chown provision /shared
USER provision
ENTRYPOINT ["bash", "/provision/provision.sh"]
