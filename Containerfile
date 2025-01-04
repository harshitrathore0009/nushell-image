FROM ubuntu:22.04 as cached

RUN apt-get update && apt-get install -y wget

FROM cached as build

ARG VERSION=0.99.1
ARG DOWNLOAD_ARCH=x86_64
ARG URL=https://github.com/nushell/nushell/releases/download/${VERSION}/nu-${VERSION}-${DOWNLOAD_ARCH}-unknown-linux-musl.tar.gz

RUN wget -q -O /tmp/archive.tar.gz "$URL" && \
    mkdir /tmp/extract/ && \
    tar -xzf /tmp/archive.tar.gz -C /tmp/extract/ && \
    mv /tmp/extract/nu* /nu/

FROM scratch 

COPY --from=build /nu/ /nu/
