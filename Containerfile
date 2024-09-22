FROM ubuntu:20.04 as cached

RUN apt-get update && apt-get install -y wget

FROM cached as build

ARG URL=https://github.com/nushell/nushell/releases/download/0.98.0/nu-0.98.0-x86_64-unknown-linux-gnu.tar.gz

RUN wget -O /tmp/archive.tar.gz "$URL" && \
    mkdir /tmp/extract/ && \
    tar -xzf /tmp/archive.tar.gz -C /tmp/extract/ && \
    mv /tmp/extract/nu* /nu/

FROM scratch 

COPY --from=build /nu/ /nu/