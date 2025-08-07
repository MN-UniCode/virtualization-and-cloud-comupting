# TASK 34. Customize the image docker.io/grafana/grafana:11.4.0
FROM docker.io/grafana/grafana:11.4.0

USER root

RUN apk add --no-cache sudo postgresql ca-certificates openssl

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

# TASK 35. Use a custom entrypoint
ENTRYPOINT [ "/entrypoint.sh" ]