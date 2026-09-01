FROM ubuntu:24.04 AS build-base

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      libssl-dev \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

FROM build-base AS tcl-builder

COPY vendor/tcl/tcl9.1b0-src.tar.gz /tmp/tcl.tar.gz
RUN install -d /build/tcl /opt/tcl \
    && tar -xzf /tmp/tcl.tar.gz --strip-components=1 -C /build/tcl

WORKDIR /build/tcl/unix
RUN ./configure \
      --prefix=/opt/tcl \
      --disable-shared \
      --disable-symbols \
    && make -j"$(nproc)" \
    && make install \
    && test "$(echo 'puts [info patchlevel]' | /opt/tcl/bin/tclsh9.1)" = "9.1b0"

FROM build-base AS fossil-builder

COPY --from=tcl-builder /opt/tcl /opt/tcl
ENV PATH="/opt/tcl/bin:${PATH}"

COPY vendor/fossil/fossil-b8c7665e121b.tar.gz /tmp/fossil.tar.gz
RUN install -d /build/fossil \
    && tar -xzf /tmp/fossil.tar.gz --strip-components=1 -C /build/fossil

WORKDIR /build/fossil
RUN ./configure \
      --prefix=/usr/local \
      --with-openssl=auto \
      --with-zlib=auto \
      --json \
    && make -j"$(nproc)" \
    && strip fossil \
    && ./fossil version | grep -F '2.29'

FROM build-base AS althttpd-builder

WORKDIR /build/althttpd
COPY vendor/althttpd/ ./
RUN make althttpd \
    && strip althttpd

FROM ubuntu:24.04

ARG FOSSILHUB_REVISION=unknown
ARG FOSSILHUB_VERSION=2026.09.01-beta.1

ENV FOSSILHUB_REVISION="${FOSSILHUB_REVISION}" \
    FOSSILHUB_VERSION="${FOSSILHUB_VERSION}"

LABEL org.opencontainers.image.title="FossilHub" \
      org.opencontainers.image.description="Tcl 9.1/Wapp hub with native Fossil repositories served by althttpd" \
      org.opencontainers.image.version="${FOSSILHUB_VERSION}" \
      org.opencontainers.image.revision="${FOSSILHUB_REVISION}"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      argon2 \
      curl \
      openssl \
      sqlite3 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 fossilhub \
    && useradd --uid 10001 --gid fossilhub --home-dir /nonexistent \
      --shell /usr/sbin/nologin fossilhub \
    && install -d -o fossilhub -g fossilhub -m 0750 /data

ENV HOME=/data \
    USER=fossilhub

COPY --from=althttpd-builder /build/althttpd/althttpd /usr/local/bin/althttpd
COPY --from=tcl-builder /opt/tcl /opt/tcl
COPY --from=fossil-builder /build/fossil/fossil /usr/local/bin/fossil
COPY vendor/wapp/wapp.tcl /opt/fossilhub/wapp.tcl
COPY docs/releases.md /opt/fossilhub/releases.md
COPY app/bin/fossilhub-entrypoint /usr/local/bin/fossilhub-entrypoint
COPY app/bin/fossilhub-index /usr/local/bin/fossilhub-index
COPY app/bin/fossilhub-init /usr/local/bin/fossilhub-init
COPY app/bin/fossilhub-platform-init /usr/local/bin/fossilhub-platform-init
COPY app/bin/fossilhub-bootstrap-admin /usr/local/bin/fossilhub-bootstrap-admin
COPY app/cgi/fossil /srv/www/default.website/fossil
COPY app/fossilhub.tcl /srv/www/default.website/index
COPY app/lib/ /srv/www/default.website/lib/
COPY app/views/ /srv/www/default.website/views/
COPY app/public/ /srv/www/default.website/public/
COPY app/public/fh.css /srv/www/default.website/fh.css

RUN ln -s /opt/tcl/bin/tclsh9.1 /usr/bin/tclsh \
    && chmod 0555 \
      /usr/local/bin/althttpd \
      /usr/local/bin/fossil \
      /usr/local/bin/fossilhub-entrypoint \
      /usr/local/bin/fossilhub-index \
      /usr/local/bin/fossilhub-init \
      /usr/local/bin/fossilhub-platform-init \
      /usr/local/bin/fossilhub-bootstrap-admin \
      /srv/www/default.website/fossil \
      /srv/www/default.website/index \
    && chmod 0444 /opt/fossilhub/wapp.tcl \
      /opt/fossilhub/releases.md \
      /srv/www/default.website/fh.css \
      /srv/www/default.website/public/fh.css \
      /srv/www/default.website/public/*.js \
      /srv/www/default.website/lib/*.tcl \
      /srv/www/default.website/views/*.tcl \
    && ln /srv/www/default.website/index \
      /srv/www/default.website/not-found.html \
    && test "$(echo 'puts [info patchlevel]' | /usr/bin/tclsh)" = "9.1b0" \
    && /usr/local/bin/fossil version | grep -F '2.29' \
    && /usr/bin/tclsh /srv/www/default.website/index --lint

USER fossilhub:fossilhub
WORKDIR /srv/www

EXPOSE 8080
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/fossilhub-entrypoint"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl --fail --silent --show-error http://127.0.0.1:8080/healthz || exit 1

CMD ["/usr/local/bin/althttpd", "--root", "/srv/www", "--port", "8080", "--logfile", "/data/althttpd-%Y%m%d.csv", "--max-child", "64", "--max-age", "3600"]
