FROM node:14.16.1-buster-slim

# install dependencies
RUN apt update && apt install -y \
    gpg \
    wget \
    build-essential \
    python3 \
    python3-dev \
    python3-pip \
    git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
ENV GPG_KEY_SERVER hkp://keyserver.ubuntu.com:80
# setup bitcoin
ARG BITCOIN_VERSION=0.21.1
ENV BITCOIN_TARBALL bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz
ENV BITCOIN_URL_BASE https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}
ENV BITCOIN_PGP_KEY 01EA5486DE18A882D4C2684590C8019E36C2E964
RUN wget -qO ${BITCOIN_TARBALL} ${BITCOIN_URL_BASE}/${BITCOIN_TARBALL} \
    && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${BITCOIN_PGP_KEY} \
    && wget -qO SHA256SUMS.asc ${BITCOIN_URL_BASE}/SHA256SUMS.asc \
    && gpg --verify SHA256SUMS.asc \
    && sha256sum --ignore-missing --check SHA256SUMS.asc \
    && tar -xzvf ${BITCOIN_TARBALL} --directory=/opt/ \
    && ln -sfn /opt/bitcoin-${BITCOIN_VERSION}/bin/* /usr/bin \
    && rm -f ${BITCOIN_TARBALL} SHA256SUMS.asc

# setup elements
ARG ELEMENTS_VERSION=0.18.1.11
ENV ELEMENTS_TARBALL elements-${ELEMENTS_VERSION}-x86_64-linux-gnu.tar.gz
ENV ELEMENTS_URL_BASE https://github.com/ElementsProject/elements/releases/download/elements-${ELEMENTS_VERSION}
ENV ELEMENTS_PGP_KEY DE10E82629A8CAD55B700B972F2A88D7F8D68E87
RUN wget -qO ${ELEMENTS_TARBALL} ${ELEMENTS_URL_BASE}/${ELEMENTS_TARBALL} \
  && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${ELEMENTS_PGP_KEY} \
  && wget -qO SHA256SUMS.asc ${ELEMENTS_URL_BASE}/SHA256SUMS.asc \
  && gpg --verify SHA256SUMS.asc \
  && sha256sum --ignore-missing --check SHA256SUMS.asc \
  && tar -xzvf ${ELEMENTS_TARBALL} --directory=/opt/ \
  && ln -sfn /opt/elements-${ELEMENTS_VERSION}/bin/* /usr/bin \
  && rm -f ${ELEMENTS_TARBALL} SHA256SUMS.asc

# setup cmake
ENV CMAKE_VERSION 3.17.2
ENV CMAKE_TARBALL cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz
ENV CMAKE_URL_BASE https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}
ENV CMAKE_PGP_KEY C6C265324BBEBDC350B513D02D2CEF1034921684
RUN wget -qO ${CMAKE_TARBALL} ${CMAKE_URL_BASE}/${CMAKE_TARBALL} \
  && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${CMAKE_PGP_KEY} \
  && wget -qO cmake-SHA-256.txt ${CMAKE_URL_BASE}/cmake-${CMAKE_VERSION}-SHA-256.txt \
  && wget -qO cmake-SHA-256.txt.asc ${CMAKE_URL_BASE}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc \
  && gpg --verify cmake-SHA-256.txt.asc \
  && sha256sum --ignore-missing --check cmake-SHA-256.txt \
  && tar -xzvf ${CMAKE_TARBALL} --directory=/opt/ \
  && ln -sfn /opt/cmake-${CMAKE_VERSION}-Linux-x86_64/bin/* /usr/bin \
  && rm -f ${CMAKE_TARBALL} cmake-SHA-256.txt cmake-SHA-256.txt.asc

WORKDIR /root

# TODO: set ENTRYPOINT