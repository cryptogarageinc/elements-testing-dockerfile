FROM python:3.11.3-slim-bullseye

# NOTE: nodedir has used by cmake-js.
RUN mkdir /var/.npm \
  && mkdir /var/.npm/_logs \
  && mkdir /var/.node \
  && chmod -R 777 /var/.npm \
  && chmod -R 777 /var/.node \
  && echo 'prefix = /var/.npm' > /root/.npmrc \
  && echo 'cache = /var/.npm' >> /root/.npmrc \
  && echo 'nodedir = /var/.node' >> /root/.npmrc

# install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    dirmngr \
    gpg \
    gpg-agent \
    wget \
    build-essential \
    nodejs \
    npm \
    git \
    ccache \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/*

RUN export PATH="/var/.npm/bin:$PATH" \
  && npm install -g n \
  && n lts

RUN python -V && node -v && npm -v

WORKDIR /tmp
ENV GPG_KEY_SERVER hkps://keyserver.ubuntu.com
# setup bitcoin
ARG BITCOIN_VERSION=24.1
ENV BITCOIN_URL_BASE https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}
ENV BITCOIN_PGP_KEY  152812300785C96444D3334D17565732E08E5E41 0AD83877C1F0CD1EE9BD660AD7CC770B81FD22A8 590B7292695AFFA5B672CBB2E13FC145CD3F4304 28F5900B1BB5D1A4B6B6D1A9ED357015286A333D 637DB1E23370F84AFF88CCE03152347D07DA627C CFB16E21C950F67FA95E558F2EEB9F5CC09526C1 F4FC70F07310028424EFC20A8E4256593F177720 D1DBF2C4B96F2DEBF4C16654410108112E7EA81F 287AE4CA1187C68C08B49CB2D11BD4F33F1DB499 F9A8737BF4FF5C89C903DF31DD78544CF91B1514 9DEAE0DC7063249FB05474681E4AED62986CD25D E463A93F5F3117EEDE6C7316BD02942421F4889F 9D3CC86A72F8494342EA5FD10A41BDC3F4FAFF1C 4DAF18FE948E7A965B30F9457E296D555E7F63A7 28E72909F1717FE9607754F8A7BEB2621678D37D 74E2DEF5D77260B98BC19438099BAD163C70FBFA
RUN BITCOIN_TARBALL=bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz \
    && echo "BITCOIN_TARBALL=$BITCOIN_TARBALL" \
    && wget -qO ${BITCOIN_TARBALL} ${BITCOIN_URL_BASE}/${BITCOIN_TARBALL} \
    && wget -qO SHA256SUMS ${BITCOIN_URL_BASE}/SHA256SUMS \
    && wget -qO SHA256SUMS.asc ${BITCOIN_URL_BASE}/SHA256SUMS.asc \
    && echo "dump RSA key" \
    && gpg --verify SHA256SUMS.asc 2>&1 | grep "using RSA key" | tr -s ' ' | cut -d ' ' -f5 \
    && echo "dump ECDSA key" \
    && gpg --verify SHA256SUMS.asc 2>&1 | grep "using ECDSA key" | tr -s ' ' | cut -d ' ' -f5 \
    && echo "dump key" \
    && gpg --verify SHA256SUMS.asc 2>&1 | grep "using " | tr -s ' ' | cut -d ' ' -f5 \
    && gpg -v --keyserver ${GPG_KEY_SERVER} --recv-keys ${BITCOIN_PGP_KEY} \
    && gpg -v --keyserver hkps://keys.openpgp.org --recv-keys 82921A4B88FD454B7EB8CE3C796C4109063D4EAF \
    && gpg -v --keyserver hkps://keys.openpgp.org --recv-keys C388F6961FB972A95678E327F62711DBDCA8AE56 \
    && sha256sum --ignore-missing --check SHA256SUMS \
    && tar -xzvf ${BITCOIN_TARBALL} --directory=/opt/ \
    && ln -sfn /opt/bitcoin-${BITCOIN_VERSION}/bin/* /usr/bin \
    && rm -f ${BITCOIN_TARBALL} SHA256SUMS.asc

#20220427: ignore gpg verify (for C388F6961FB972A95678E327F62711DBDCA8AE56)
#    && gpg --verify -v SHA256SUMS.asc \
#    && sha256sum --ignore-missing --check SHA256SUMS \


# setup elements
ARG ELEMENTS_VERSION=22.1.1
ENV ELEMENTS_URL_BASE https://github.com/ElementsProject/elements/releases/download/elements-${ELEMENTS_VERSION}
ENV ELEMENTS_PGP_KEY DE10E82629A8CAD55B700B972F2A88D7F8D68E87 BD0F3062F87842410B06A0432F656B0610604482
RUN ELEMENTS_TARBALL=elements-${ELEMENTS_VERSION}-x86_64-linux-gnu.tar.gz \
    && echo "ELEMENTS_TARBALL=$ELEMENTS_TARBALL" \
    && wget -qO ${ELEMENTS_TARBALL} ${ELEMENTS_URL_BASE}/${ELEMENTS_TARBALL} \
    && gpg -v --keyserver ${GPG_KEY_SERVER} --recv-keys ${ELEMENTS_PGP_KEY} \
    && wget -qO SHA256SUMS.asc ${ELEMENTS_URL_BASE}/SHA256SUMS.asc \
    && gpg --verify SHA256SUMS.asc \
    && sha256sum --ignore-missing --check SHA256SUMS.asc \
    && tar -xzvf ${ELEMENTS_TARBALL} --directory=/opt/ \
    && ln -sfn /opt/elements-${ELEMENTS_VERSION}/bin/* /usr/bin \
    && rm -f ${ELEMENTS_TARBALL} SHA256SUMS.asc

# unsigned 0.21.0
#  && gpg --verify SHA256SUMS.asc \


# setup cmake
ENV CMAKE_VERSION 3.26.4
ENV CMAKE_URL_BASE https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}
ENV CMAKE_PGP_KEY 2D2CEF1034921684
RUN CMAKE_TARBALL=cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
    && echo "CMAKE_TARBALL=$CMAKE_TARBALL" \
    && wget -qO ${CMAKE_TARBALL} ${CMAKE_URL_BASE}/${CMAKE_TARBALL} \
    && gpg --keyserver ${GPG_KEY_SERVER} --recv-keys ${CMAKE_PGP_KEY} \
    && wget -qO cmake-SHA-256.txt ${CMAKE_URL_BASE}/cmake-${CMAKE_VERSION}-SHA-256.txt \
    && wget -qO cmake-SHA-256.txt.asc ${CMAKE_URL_BASE}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc \
    && gpg --verify cmake-SHA-256.txt.asc \
    && sha256sum --ignore-missing --check cmake-SHA-256.txt \
    && tar -xzvf ${CMAKE_TARBALL} --directory=/opt/ \
    && ln -sfn /opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/* /usr/bin \
    && rm -f ${CMAKE_TARBALL} cmake-*SHA-256.txt*

ENV PATH /var/.npm/bin:/opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin:/opt/elements-${ELEMENTS_VERSION}/bin:/opt/bitcoin-${BITCOIN_VERSION}/bin:$PATH

COPY ./script/check.sh  /usr/local/bin/check.sh
RUN chmod +x /usr/local/bin/check.sh

ENV USER_NAME testuser
RUN useradd --user-group --create-home --shell /bin/false ${USER_NAME} \
  && mkdir /github \
  && mkdir /workspace \
  && chmod -R 777 /github \
  && chmod -R 777 /workspace \
  && chown ${USER_NAME}:${USER_NAME} /github \
  && chown ${USER_NAME}:${USER_NAME} /workspace \
  && chown -R ${USER_NAME}:${USER_NAME} /var/.npm \
  && chown -R ${USER_NAME}:${USER_NAME} /var/.node

USER ${USER_NAME}

WORKDIR /workspace

RUN echo 'prefix = /var/.npm' > ~/.npmrc \
  && echo 'cache = /var/.npm' >> ~/.npmrc\
  && echo 'nodedir = /var/.node' >> ~/.npmrc

RUN cmake --version

CMD bitcoin-cli --version && elements-cli --version \
  && python -V && echo "node version" && node -v && echo "npm version" && npm -v \
  && cmake --version && env

# TODO: set ENTRYPOINT
