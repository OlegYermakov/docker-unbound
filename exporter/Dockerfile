FROM golang:1.16-alpine as builder
LABEL maintainer="Oleg Ermakov"

WORKDIR /unbound_exporter

RUN apk update && \
    apk add --no-cache git && \
    apk add --no-cache bash && \
    rm  -rf /tmp/../tmp/../tmp/../tmp/../tmp/* /var/cache/apk/* && \
    go get github.com/kumina/unbound_exporter && \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app github.com/kumina/unbound_exporter

FROM alpine:latest
LABEL maintainer="Oleg Ermakov"

ENV NAME=unbound-exporter \
    VERSION=1.2.0 \
    SUMMARY="${NAME} is statistics exporter to prometheus." \
    DESCRIPTION="${NAME} is statistics exporter to prometheus."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="unbound_exporter ${VERSION}" \
      name="olligator/${NAME}" \
      maintainer="Oleg Ermakov"

WORKDIR /opt
ENV PATH /opt/unbound/sbin:/opt/openssl/bin:"$PATH"
COPY --from=build /unbound_exporter/app ./unbound_exporter
COPY exporter.sh /
RUN chmod +x /exporter.sh && \
    apk add --no-cache curl

EXPOSE 9167/tcp
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD curl -s http://127.0.0.1:9167 -o /dev/null || exit 1
CMD ["/exporter.sh"]
