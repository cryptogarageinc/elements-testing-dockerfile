FROM python:3.9.7-slim-buster

# install dependencies
RUN apt-get update && apt-get install -y --no-install-recommend \
    gpg \
    wget \
    build-essential \
    nodejs \
    npm \
    git \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g n \
  && n lts

RUN python -V && node -v

WORKDIR /tmp
ENV GPG_KEY_SERVER hkps://keyserver.ubuntu.com
# setup bitcoin
ARG BITCOIN_VERSION=22.0
ENV BITCOIN_TARBALL bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz
ENV BITCOIN_URL_BASE https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}
ENV BITCOIN_PGP_KEY 982A193E3CE0EED535E09023188CBB2648416AD5 0CCBAAFD76A2ECE2CCD3141DE2FFD5B1D88CA97D 152812300785C96444D3334D17565732E08E5E41 0AD83877C1F0CD1EE9BD660AD7CC770B81FD22A8 590B7292695AFFA5B672CBB2E13FC145CD3F4304 28F5900B1BB5D1A4B6B6D1A9ED357015286A333D 637DB1E23370F84AFF88CCE03152347D07DA627C CFB16E21C950F67FA95E558F2EEB9F5CC09526C1 6E01EEC9656903B0542B8F1003DB6322267C373B D1DBF2C4B96F2DEBF4C16654410108112E7EA81F 82921A4B88FD454B7EB8CE3C796C4109063D4EAF 9DEAE0DC7063249FB05474681E4AED62986CD25D 9D3CC86A72F8494342EA5FD10A41BDC3F4FAFF1C 74E2DEF5D77260B98BC19438099BAD163C70FBFA 71A3B16735405025D447E8F274810B012346C9A6
# 82921A4B88FD454B7EB8CE3C796C4109063D4EAF
RUN wget -qO ${BITCOIN_TARBALL} ${BITCOIN_URL_BASE}/${BITCOIN_TARBALL} \
    && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${BITCOIN_PGP_KEY} \
    && gpg --keyserver hkps://keys.openpgp.org --recv-keys 82921A4B88FD454B7EB8CE3C796C4109063D4EAF \
    && wget -qO SHA256SUMS ${BITCOIN_URL_BASE}/SHA256SUMS \
    && wget -qO SHA256SUMS.asc ${BITCOIN_URL_BASE}/SHA256SUMS.asc \
    && gpg --verify SHA256SUMS.asc \
    && sha256sum --ignore-missing --check SHA256SUMS \
    && tar -xzvf ${BITCOIN_TARBALL} --directory=/opt/ \
    && ln -sfn /opt/bitcoin-${BITCOIN_VERSION}/bin/* /usr/bin \
    && rm -f ${BITCOIN_TARBALL} SHA256SUMS.asc

# setup elements
ARG ELEMENTS_VERSION=0.21.0
ENV ELEMENTS_TARBALL elements-elements-${ELEMENTS_VERSION}-x86_64-linux-gnu.tar.gz
ENV ELEMENTS_URL_BASE https://github.com/ElementsProject/elements/releases/download/elements-${ELEMENTS_VERSION}
ENV ELEMENTS_PGP_KEY DE10E82629A8CAD55B700B972F2A88D7F8D68E87
RUN wget -qO ${ELEMENTS_TARBALL} ${ELEMENTS_URL_BASE}/${ELEMENTS_TARBALL} \
  && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${ELEMENTS_PGP_KEY} \
  && wget -qO SHA256SUMS.asc ${ELEMENTS_URL_BASE}/SHA256SUMS.asc \
  && sha256sum --ignore-missing --check SHA256SUMS.asc \
  && tar -xzvf ${ELEMENTS_TARBALL} --directory=/opt/ \
  && mv /opt/elements-elements-* /opt/elements-${ELEMENTS_VERSION} \
  && ln -sfn /opt/elements-${ELEMENTS_VERSION}/bin/* /usr/bin \
  && rm -f ${ELEMENTS_TARBALL} SHA256SUMS.asc

# unsigned 0.21.0
#  && gpg --verify SHA256SUMS.asc \


# setup cmake
ENV CMAKE_VERSION 3.21.3
ENV CMAKE_TARBALL cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
ENV CMAKE_URL_BASE https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}
ENV CMAKE_PGP_KEY 2D2CEF1034921684
RUN wget -qO ${CMAKE_TARBALL} ${CMAKE_URL_BASE}/${CMAKE_TARBALL} \
  && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${CMAKE_PGP_KEY} \
  && wget -qO cmake-SHA-256.txt ${CMAKE_URL_BASE}/cmake-${CMAKE_VERSION}-SHA-256.txt \
  && wget -qO cmake-SHA-256.txt.asc ${CMAKE_URL_BASE}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc \
  && gpg --verify cmake-SHA-256.txt.asc \
  && sha256sum --ignore-missing --check cmake-SHA-256.txt \
  && tar -xzvf ${CMAKE_TARBALL} --directory=/opt/ \
  && ln -sfn /opt/cmake-${CMAKE_VERSION}-Linux-x86_64/bin/* /usr/bin \
  && rm -f ${CMAKE_TARBALL} cmake-*SHA-256.txt*

ENV PATH $PATH:/opt/cmake-3.21.3-linux-x86_64/bin:/opt/elements-${ELEMENTS_VERSION}/bin:/opt/bitcoin-${BITCOIN_VERSION}/bin

WORKDIR /root

CMD bitcoin-cli --version && elements-cli --version \
  && python -V && node -v && cmake --version && env

# TODO: set ENTRYPOINT