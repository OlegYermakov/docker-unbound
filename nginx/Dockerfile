FROM alpine:3.13 as openssl
#FROM olligator/alpine-dev:latest as openssl
LABEL maintainer="Oleg Ermakov"

ENV VERSION_OPENSSL=openssl-1.1.1k \
    SOURCE_OPENSSL=https://www.openssl.org/source/ \
    OPGP_OPENSSL=8657ABB260F056B1E5190839D9C4D26D0E604491

WORKDIR /tmp/src

RUN apk add --no-cache --update --virtual .build-deps alpine-sdk wget bash gnupg perl linux-headers && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz -o openssl.tar.gz && \
    echo "`curl $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz.sha256`  ./openssl.tar.gz" | sha256sum -c - && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz.asc -o openssl.tar.gz.asc && \
    GNUPGHOME="$(mktemp -d)" && export GNUPGHOME && \
    gpg --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$OPGP_OPENSSL" && \
    gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
    tar xzf openssl.tar.gz && \
    cd $VERSION_OPENSSL && \
    ./config --prefix=/opt/openssl no-weak-ssl-ciphers no-ssl3 no-shared enable-ec_nistp_64_gcc_128 \
    -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong && \
    make depend && \
    make -j2 && \
    make install_sw && \
    apk del .build-deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

FROM alpine:3.13 as nginx
#FROM olligator/alpine-dev:latest as nginx
LABEL maintainer="Oleg Ermakov"

#http://nginx.org/download/nginx-1.18.0.tar.gz
#http://nginx.org/download/nginx-1.18.0.tar.gz.asc

ENV NAME=nginx \
    NGINX_VERSION=1.18.0 \
    NGINX_DOWNLOAD_URL=http://nginx.org/download/ \
    AR=/usr/bin/gcc-ar \
    RANLIB=gcc-ranlib \
    NM=gcc-nm \
    AR_FLAGS=cr \
    CMAKE_AR=/usr/bin/gcc-ar

WORKDIR /tmp/src
COPY --from=openssl /opt/openssl /opt/openssl

RUN apk add --no-cache --update --virtual .build-deps alpine-sdk wget bash linux-headers libevent-dev expat-dev pcre-dev && \
    curl -sSL "$NGINX_DOWNLOAD_URL/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz && \
    tar xzf nginx.tar.gz && \
    rm -f nginx.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    addgroup _nginx && \
    adduser -G _nginx -s /etc -D -H -h /dev/null _nginx && \
    ./configure \
        --prefix=/opt/nginx \
        --with-openssl=/opt/openssl \
        --without-http_gzip_module \
        --with-stream && \
    make -j6 install && \
#    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apk del .build-deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

FROM alpine:3.13
LABEL maintainer="Oleg Ermakov"

ENV NAME=docker-nginx \
    VERSION=1.0 \
    SUMMARY="${NAME} is DoT proxy for unbound resolver." \
    DESCRIPTION="${NAME} is DoT proxy for unbound resolver."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Nginx ${VERSION}" \
      name="olligator/${NAME}" \
      maintainer="Oleg Ermakov"

WORKDIR /tmp/src

COPY --from=nginx /opt /opt

RUN apk add --no-cache --update --virtual ldnsutils expat bash libevent perl ca-certificates && \
    addgroup _nginx && \
    adduser -G _nginx -s /etc -D -H -h /dev/null _nginx && \
    rm -rf \
        /opt/nginx/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

COPY configs/*.conf /opt/nginx/

COPY nginx.sh /
RUN chmod +x /nginx.sh

WORKDIR /opt/nginx/

ENV PATH /opt/nginx/sbin:/opt/openssl/bin:"$PATH"

EXPOSE 853/tcp
EXPOSE 853/udp

#HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD drill @127.0.0.1 ya.ru || exit 1

CMD ["/nginx.sh"]
