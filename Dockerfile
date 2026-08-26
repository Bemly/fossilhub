FROM ubuntu:24.04 AS althttpd-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/althttpd
COPY vendor/althttpd/ ./
RUN make althttpd \
    && strip althttpd

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="FossilHub" \
      org.opencontainers.image.description="Tcl/Wapp Fossil repository hub served by althttpd" \
      org.opencontainers.image.version="0.1.0"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      sqlite3 \
      tcl8.6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 fossilhub \
    && useradd --uid 10001 --gid fossilhub --home-dir /nonexistent \
      --shell /usr/sbin/nologin fossilhub \
    && ln -s /usr/bin/tclsh8.6 /usr/local/bin/tclsh

COPY --from=althttpd-builder /build/althttpd/althttpd /usr/local/bin/althttpd
COPY vendor/wapp/wapp.tcl /opt/fossilhub/wapp.tcl
COPY app/fossilhub.tcl /srv/www/default.website/index
COPY app/templates/ /srv/www/default.website/templates/
COPY app/public/ /srv/www/default.website/public/
COPY app/public/fh.css /srv/www/default.website/fh.css

RUN chmod 0555 /usr/local/bin/althttpd /srv/www/default.website/index \
    && chmod 0444 /opt/fossilhub/wapp.tcl \
      /srv/www/default.website/fh.css \
      /srv/www/default.website/public/fh.css \
      /srv/www/default.website/templates/*.html \
    && ln /srv/www/default.website/index \
      /srv/www/default.website/not-found.html \
    && install -d -o fossilhub -g fossilhub -m 0750 /data \
    && /usr/local/bin/tclsh /srv/www/default.website/index --lint

USER fossilhub:fossilhub
WORKDIR /srv/www

EXPOSE 8080
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl --fail --silent --show-error http://127.0.0.1:8080/healthz || exit 1

CMD ["/usr/local/bin/althttpd", "--root", "/srv/www", "--port", "8080", "--logfile", "/data/althttpd-%Y%m%d.csv", "--max-child", "64", "--max-age", "3600"]
