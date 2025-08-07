FROM ghcr.io/dexidp/dex:v2.41.1-alpine

USER root

RUN apk add --no-cache postgresql-client

RUN chown -R 1001:1001 /etc/dex

USER 1001

CMD ["/bin/sh", "-c", "until /usr/bin/pg_isready -h db -U dex; do sleep 5; done; /usr/local/bin/dex serve /etc/dex/config.docker.yaml"]