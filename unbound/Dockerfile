FROM alpine:latest as openssl
#FROM olligator/alpine-dev:latest as openssl
LABEL maintainer="Oleg Ermakov"

ENV VERSION_OPENSSL=openssl-1.1.1n \
    SOURCE_OPENSSL=https://www.openssl.org/source/ \
    OPGP_OPENSSL=8657ABB260F056B1E5190839D9C4D26D0E604491

WORKDIR /tmp/src

RUN apk add --no-cache --update --virtual .build-deps alpine-sdk wget bash gnupg perl linux-headers && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz -o openssl.tar.gz && \
    echo "`curl $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz.sha256`  ./openssl.tar.gz" | sha256sum -c - && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz.asc -o openssl.tar.gz.asc && \
    GNUPGHOME="$(mktemp -d)" && export GNUPGHOME && \
    ( gpg --no-tty --keyserver hkps://keys.openpgp.org/ --recv-keys "$OPGP_OPENSSL" ) && \
    gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
    tar xzf openssl.tar.gz && \
    cd $VERSION_OPENSSL && \
    ./config --prefix=/opt/openssl no-weak-ssl-ciphers no-ssl3 no-shared enable-ec_nistp_64_gcc_128 \
    -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong && \
    make depend && \
    make -j6 && \
    make install_sw && \
    apk del .build-deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

FROM alpine:latest as unbound
#FROM olligator/alpine-dev:latest as unbound
LABEL maintainer="Oleg Ermakov"

ENV NAME=unbound \
    UNBOUND_VERSION=1.15.0 \
    UNBOUND_DOWNLOAD_URL=https://nlnetlabs.nl/downloads/unbound \
    AR=/usr/bin/gcc-ar \
    RANLIB=gcc-ranlib \
    NM=gcc-nm \
    AR_FLAGS=cr \
    CMAKE_AR=/usr/bin/gcc-ar

WORKDIR /tmp/src
COPY --from=openssl /opt/openssl /opt/openssl

RUN apk add --no-cache --update --virtual .build-deps alpine-sdk wget bash linux-headers libevent-dev expat-dev && \
    curl -sSL "$UNBOUND_DOWNLOAD_URL/unbound-${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz && \
    echo "`curl $UNBOUND_DOWNLOAD_URL/unbound-${UNBOUND_VERSION}.tar.gz.sha256` *unbound.tar.gz" | sha256sum -c - && \
    tar xzf unbound.tar.gz && \
    rm -f unbound.tar.gz && \
    cd unbound-${UNBOUND_VERSION} && \
    addgroup _unbound && \
    adduser -G _unbound -s /etc -D -H -h /dev/null _unbound && \
    ./configure \
    #    --disable-dependency-tracking \
        --prefix=/opt/unbound \
        --with-pthreads \
        --with-username=_unbound \
        --with-ssl=/opt/openssl \
        --with-libevent \
        --enable-event-api && \
    make -j6 install && \
    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apk del .build-deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

FROM alpine:latest
LABEL maintainer="Oleg Ermakov"

ENV NAME=docker-unbound \
    VERSION=1.0 \
    SUMMARY="${NAME} is a validating, recursive, and caching DNS resolver." \
    DESCRIPTION="${NAME} is a validating, recursive, and caching DNS resolver."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Unbound ${VERSION}" \
      name="olligator/${NAME}" \
      maintainer="Oleg Ermakov"

WORKDIR /tmp/src

COPY --from=unbound /opt /opt

RUN apk add --no-cache --update --virtual ldnsutils expat bash libevent perl ca-certificates && \
    addgroup _unbound && \
    adduser -G _unbound -s /etc -D -H -h /dev/null _unbound && \
    rm -rf \
        /opt/unbound/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

COPY configs/*.conf /opt/unbound/

COPY unbound.sh /
RUN chmod +x /unbound.sh

WORKDIR /opt/unbound/

ENV PATH /opt/unbound/sbin:/opt/openssl/bin:"$PATH"

EXPOSE 53/tcp
EXPOSE 53/udp

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD drill @127.0.0.1 ya.ru || exit 1

CMD ["/unbound.sh"]
