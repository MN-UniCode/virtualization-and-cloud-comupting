# TASK 29. Customize the image codeberg.org/forgejo/forgejo:9.0.3
FROM codeberg.org/forgejo/forgejo:9.0.3

RUN apk add --no-cache sudo postgresql ca-certificates openssl

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

# TASK 30. Use the custom entrypoint found in files/images/forgejo
ENTRYPOINT [ "/entrypoint.sh" ]