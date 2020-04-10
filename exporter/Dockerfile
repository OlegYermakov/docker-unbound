FROM alpine:edge as unbound_exporter
LABEL maintainer="Oleg Ermakov"

WORKDIR /tmp/src

RUN apk add --update --virtual .build-deps ca-certificates git go libc-dev && \
git clone https://github.com/kumina/unbound_exporter && \
cd unbound_exporter && \
go build --ldflags '-extldflags "-static"' && \
cp unbound_exporter /opt && \
apk del .build-deps && \
    rm -rf \
    /tmp/* \
    /var/tmp/* \
    /var/lib/apk/*

FROM alpine:latest
LABEL maintainer="Oleg Ermakov"

ENV NAME=unbound-exporter \
    VERSION=1.0 \
    SUMMARY="${NAME} is statistics exporter to prometheus." \
    DESCRIPTION="${NAME} is statistics exporter to prometheus."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="unbound_exporter ${VERSION}" \
      name="olligator/${NAME}" \
      maintainer="Oleg Ermakov"

COPY --from=unbound_exporter /opt /opt

RUN apk add --no-cache --update --virtual ldnsutils expat bash libevent perl ca-certificates && \
    rm -rf \
        /opt/unbound/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apk/*

WORKDIR /opt/unbound/
ENV PATH /opt/unbound/sbin:/opt/openssl/bin:"$PATH"
COPY exporter.sh /
RUN chmod +x /exporter.sh
EXPOSE 9167/tcp

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD curl -s http://127.0.0.1:9167 -o /dev/null || exit 1

CMD ["/exporter.sh"]
