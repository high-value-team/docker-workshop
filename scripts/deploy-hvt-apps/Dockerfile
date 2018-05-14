FROM alpine:3.6

ENV RANCHER_CLI_VERSION="0.6.9"

RUN apk --no-cache add --virtual build-deps curl \
  && curl -L "https://releases.rancher.com/cli/v${RANCHER_CLI_VERSION}/binaries/linux-amd64/rancher.xz" | xzcat - > /usr/local/bin/rancher \
  && chmod +x /usr/local/bin/rancher \
  && apk del build-deps \
  && apk --no-cache add openssl ca-certificates \
  && update-ca-certificates

COPY . /data
WORKDIR /data
RUN chmod +x run.sh

ENTRYPOINT sh run.sh