#
# Copyright (2019-2021) Petr Ospalý <pospaly@opennebula.io>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS builder

ARG KEA_VERSION
ARG KEA_INSTALLPREFIX
ARG MAKE_JOBS
ARG KEEP_BUILDBLOB
ARG KEEP_BUILDDEPS
ARG INSTALL_HOOKS
ARG USE_DISTRO_PACKAGE

ENV KEA_VERSION "${KEA_VERSION}"
ENV KEA_INSTALLPREFIX "${KEA_INSTALLPREFIX}"
ENV MAKE_JOBS "${MAKE_JOBS}"
ENV KEEP_BUILDBLOB "${KEEP_BUILDBLOB}"
ENV KEEP_BUILDDEPS "${KEEP_BUILDDEPS}"
ENV INSTALL_HOOKS "${INSTALL_HOOKS}"
ENV USE_DISTRO_PACKAGE "${USE_DISTRO_PACKAGE}"

#
# build and install ISC Kea
#

# build script
WORKDIR /ikea
COPY build.sh ./
RUN chmod 0755 build.sh

# first stage: suite
RUN env KEEP_BUILDDEPS=yes ./build.sh suite

# second stage: hooks
COPY abuild.conf /
COPY src/hooks/ ./hooks/
RUN ./build.sh hooks


###############################################################################
# final image
###############################################################################

ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Petr Ospalý (osp) <petr@ospalax.cz>"

ARG KEA_VERSION
ARG KEA_INSTALLPREFIX
ARG USE_DISTRO_PACKAGE

ENV KEA_VERSION "${KEA_VERSION}"

RUN \
    apk update \
    && \
    apk add --no-cache \
        boost \
        postgresql-client \
        mariadb-client \
        mariadb-connector-c \
        cassandra-cpp-driver \
        openssl \
        ca-certificates \
        curl \
        xz \
        python3 \
    && { \
        apk add --no-cache log4cplus \
        || \
        apk add --no-cache \
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
            log4cplus \
        ; \
    } \
    && { \
        _use_distro_package=$(echo "${USE_DISTRO_PACKAGE}" | \
            tr '[:upper:]' '[:lower:]') ; \
        if [ "$_use_distro_package" = "yes" ] ; then \
            apk add --no-cache "kea~${KEA_VERSION}" ; \
        fi ; \
    } \
    && \
    rm -rf /var/cache/apk/*

# install build artifact
COPY --from=builder "${KEA_INSTALLPREFIX}" "${KEA_INSTALLPREFIX}"
COPY --from=builder /etc/ld-musl-* /etc/

# save alpine packages
COPY --from=builder /packages/ /packages/

RUN test -e "${KEA_INSTALLPREFIX}/lib" && ldconfig "${KEA_INSTALLPREFIX}/lib"

# run microservice
#ENTRYPOINT ["${KEA_INSTALLPREFIX}/sbin/kea-dhcp4"]
#CMD ["-c", "${KEA_INSTALLPREFIX}/etc/kea/kea-dhcp4.conf"]
