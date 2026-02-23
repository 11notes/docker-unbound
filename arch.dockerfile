# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/unbound \
      BUILD_SRC=https://github.com/NLnetLabs/unbound.git \
      APP_VERSION=0 \
      APP_OPENSSL_VERSION=0
  ARG BUILD_BIN=${BUILD_ROOT}/unbound \
      BUILD_DEPENDENCY_OPENSSL_TAR=openssl-${APP_OPENSSL_VERSION}.tar.gz \
      BUILD_DEPENDENCY_OPENSSL_ROOT=/openssl-${APP_OPENSSL_VERSION}

  # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:dnslookup AS distroless-dnslookup
  FROM 11notes/util:bin AS util-bin

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: OPENSSL
  FROM alpine AS openssl
  COPY --from=util-bin / /
  ARG APP_OPENSSL_VERSION \
      TARGETARCH \
      TARGETVARIANT \
      BUILD_DEPENDENCY_OPENSSL_TAR \
      BUILD_DEPENDENCY_OPENSSL_ROOT

  RUN set -ex; \
    apk --update --no-cache add \
      git \
      build-base \
      perl \
      libidn2-dev \
      libevent-dev \
      linux-headers \
      apk-tools \
      curl \
      jq \
      tar;

  RUN set -ex; \
    eleven github asset openssl/openssl openssl-${APP_OPENSSL_VERSION} ${BUILD_DEPENDENCY_OPENSSL_TAR};

  RUN set -ex; \
    cd ${BUILD_DEPENDENCY_OPENSSL_ROOT}; \
    ARCHEXT=""; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      "armv7") \
        ARCHEXT=linux-generic32; \
      ;; \
    esac; \
    ./Configure ${ARCHEXT} \
      no-weak-ssl-ciphers \
      no-apps \
      no-docs \
      no-legacy \
      no-ssl3 \
      no-err \
      no-autoerrinit \
      enable-tfo \
      enable-quic \
      enable-ktls \
      enable-ec_nistp_64_gcc_128 \
      -fPIC \
      -DOPENSSL_NO_HEARTBEATS \
      -fstack-protector-strong \
      -fstack-clash-protection \
      --prefix=/usr/local/openssl \
      --openssldir=/usr/local/openssl \
      --libdir=/usr/local/openssl/lib; \
    make -s -j $(nproc) 2>&1 > /dev/null; \
    make -s -j $(nproc) install_sw 2>&1 > /dev/null;

# :: UNBOUND
  FROM openssl AS build
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  ENV CFLAGS="-O2"

  RUN set -ex; \
    apk --update --no-cache add \
      flex-dev \
      bison \
      build-base\
      libsodium-dev \
      libsodium-static \
      linux-headers \
      nghttp2-dev \
      nghttp2-static \
      ngtcp2-dev \
      libevent-dev \
      libevent-static \
      expat-dev \
      expat-static \
      libmnl-dev \
      libmnl-static \
      hiredis-dev;

  RUN set -ex; \
    git clone ${BUILD_SRC} -b release-${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --prefix="/unbound" \
      --with-chroot-dir= \
      --with-username="" \
      --with-pthreads \
      --with-libevent \
      --with-libnghttp2 \
      --with-libhiredis \
      --with-ssl=/usr/local/openssl \
      --without-pythonmodule \
      --without-pyunbound \
      --enable-ipset \
      --enable-fully-static \
      --enable-event-api \
      --enable-tfo-client \
      --enable-tfo-server \
      --enable-dnscrypt \
      --enable-cachedb \
      --enable-subnet \
      --enable-relro-now \
      --enable-pie \
      --enable-static-exe \
      --disable-shared \
      --disable-flto \
      --disable-rpath; \
    make -s -j $(nproc) 2>&1 > /dev/null;

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-dnslookup / /
    COPY --from=build /distroless/ /
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs /

# :: Volumes
  VOLUME ["${APP_ROOT}/etc"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/dnslookup", ".", "NS",  "127.0.0.1"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/unbound"]
  CMD ["-p", "-d", "-c", "/unbound/etc/default.conf"]