FROM golang:alpine

ENV TERRAFORM_VERSION=0.11.7
ENV TERRAFORM_PROVIDER_AWS_VERSION=1.21.0
ENV TERRAFORM_PROVIDER_TEMPLATE_VERSION=1.0.0

RUN apk add --update git bash openssh curl make

ENV TF_DEV=true
ENV TF_RELEASE=true

WORKDIR $GOPATH/src/github.com/hashicorp/terraform

RUN git clone https://github.com/hashicorp/terraform.git ./ && \
    git checkout v${TERRAFORM_VERSION} && \
    /bin/bash scripts/build.sh

RUN mkdir -p $GOPATH/src/github.com/terraform-providers && \
    cd $GOPATH/src/github.com/terraform-providers && \
    git clone https://github.com/terraform-providers/terraform-provider-aws.git && \
    cd $GOPATH/src/github.com/terraform-providers/terraform-provider-aws && \
    git checkout v${TERRAFORM_PROVIDER_AWS_VERSION} && \
    make


RUN mkdir -p $GOPATH/src/github.com/terraform-providers && \
    cd $GOPATH/src/github.com/terraform-providers && \
    git clone https://github.com/terraform-providers/terraform-provider-template.git && \
    cd $GOPATH/src/github.com/terraform-providers/terraform-provider-template && \
    git checkout v${TERRAFORM_PROVIDER_TEMPLATE_VERSION} && \
    make

COPY terraform-provider-abc /terraform-provider-abc
RUN cd /terraform-provider-abc && go build && cp terraform-provider-abc /go/bin


ENV RANCHER_CLI_VERSION="0.6.9"

RUN apk --no-cache add --virtual build-deps curl \
  && curl -L https://github.com/drone/drone-cli/releases/download/v0.8.5/drone_linux_amd64.tar.gz  | tar xz \
  && mv drone /usr/local/bin/drone \
  && chmod +x /usr/local/bin/drone \
  && apk del build-deps \
  && apk --no-cache add openssl ca-certificates \
  && update-ca-certificates

WORKDIR $GOPATH