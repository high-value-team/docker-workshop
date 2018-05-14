FROM alpine:3.6

ENV RANCHER_CLI_VERSION="0.6.9"

RUN apk --no-cache add --virtual build-deps curl \
  && curl -L https://github.com/drone/drone-cli/releases/download/v0.8.5/drone_linux_amd64.tar.gz  | tar xz \
  && mv drone /usr/local/bin/drone \
  && chmod +x /usr/local/bin/drone \
  && apk del build-deps \
  && apk --no-cache add openssl ca-certificates \
  && update-ca-certificates

COPY . /data
WORKDIR /data
RUN chmod +x run.sh

ENTRYPOINT sh run.sh