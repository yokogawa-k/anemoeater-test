FROM debian

ENV DEBIAN_FRONTEND noninteractive
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        tcpdump \
        curl \
        ca-certificates \
        gnupg \
        procps

RUN set -ex \
    && curl -sLO https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh \
    && bash script.deb.sh \
    && apt-get install -y sysbench \
    && rm script.deb.sh
