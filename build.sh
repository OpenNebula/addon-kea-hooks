#!/bin/sh

#
# Copyright (2019) Petr Ospalý <petr@ospalax.cz>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

set -ex

# Stages:
# 1. suite (ISC Kea itself)
# 2. hooks (custom hooks)
STAGE="${1:-suite}"

KEA_INSTALLPREFIX="${KEA_INSTALLPREFIX:-/usr/local}"
MAKE_JOBS="${MAKE_JOBS:-1}"

#
# functions
#

install_kea_runtime_deps()
{
    apk update

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
        ;

    # try to install stable version first, then try from edge or fail
    apk add --no-cache log4cplus \
    || \
    apk add --no-cache \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        log4cplus
}

install_kea_build_deps()
{
    apk add --no-cache --virtual .build-deps \
        build-base \
        file \
        gnupg \
        pkgconf \
        automake \
        libtool \
        docbook-xsl \
        libxslt \
        doxygen \
        openssl-dev \
        boost-dev \
        postgresql-dev \
        mariadb-dev \
        musl-dev \
        zlib-dev \
        bzip2-dev \
        sqlite-dev \
        cassandra-cpp-driver-dev \
        python3-dev \
        ;

    # try to install stable version first, then try from edge or fail
    apk add --no-cache log4cplus-dev \
    || \
    apk add --no-cache \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        log4cplus-dev
}

install_kea_from_source()
{
    curl -LOR \
        "https://ftp.isc.org/isc/kea/${KEA_VERSION}/kea-${KEA_VERSION}.tar.gz{,.sha512.asc}"

    mkdir -m 0700 -p /root/.gnupg

    gpg2 \
        --no-options \
        --verbose \
        --keyid-format 0xlong \
        --keyserver-options \
        auto-key-retrieve=true \
        --verify \
        kea-${KEA_VERSION}.tar.gz*asc \
        kea-${KEA_VERSION}.tar.gz

    tar xzpf kea-${KEA_VERSION}.tar.gz

    rm -rf \
        kea-${KEA_VERSION}.tar.gz* \
        /root/.gnupg* \

    cd kea-${KEA_VERSION}

    ./configure \
        --prefix="${KEA_INSTALLPREFIX}" \
        --enable-shell \
        --with-mysql=/usr/bin/mysql_config \
        --with-pgsql=/usr/bin/pg_config \
        --with-cql=/usr/bin/pkg-config \
        --with-openssl \
        --with-log4cplus=/usr \
        ;

    make -j ${MAKE_JOBS} && make install-strip

    cd -

    # musl linker search paths
    if ! [ -f /etc/ld-musl-$(arch).path ] ; then
        echo "/lib:/usr/local/lib:/usr/lib" > /etc/ld-musl-$(arch).path
        chmod 0644 /etc/ld-musl-$(arch).path
    fi

    echo "${KEA_INSTALLPREFIX}/lib" >> /etc/ld-musl-$(arch).path
    ldconfig "${KEA_INSTALLPREFIX}/lib"
}

install_hooks_from_source()
{
    for hook in /ikea/hooks/*/ ; do
        if [ -d "${hook}/${KEA_VERSION}" ] ; then
            cd "${hook}/${KEA_VERSION}"
            make install
            cd -
        fi
    done
}

clean_apk()
{
    apk --purge del .build-deps log4cplus-dev
}

# arg: <variable name>
is_true()
{
    _value=$(eval echo "\$${1}" | tr '[:upper:]' '[:lower:]')
    case "$_value" in
        yes|true)
            return 0
            ;;
    esac

    return 1
}

#
# main
#

# sanity checks first
if [ -z "$KEA_VERSION" ] ; then
    echo "ERROR: Variable 'KEA_VERSION' is unset" 1>&2
    exit 1
fi

case "$STAGE" in
    suite)
        # install packages
        install_kea_runtime_deps
        install_kea_build_deps

        # build and install ISC Kea suite
        install_kea_from_source

        # delete blob?
        if ! is_true KEEP_BUILDBLOB ; then
            rm -rf /ikea/kea-${KEA_VERSION}*
        fi
        ;;
    hooks)
        # install packages
        install_kea_runtime_deps
        install_kea_build_deps

        # build and install ISC Kea hooks
        if is_true INSTALL_HOOKS ; then
            install_hooks_from_source
        fi

        # delete blob?
        if ! is_true KEEP_BUILDBLOB ; then
            rm -rf /ikea/hooks
        fi
        ;;
    *)
        echo "ERROR: Unknown stage: '${STAGE}' (suite|hooks)" 1>&2
        exit 1
        ;;
esac

# cleanup
if ! is_true KEEP_BUILDDEPS ; then
    clean_apk
fi

# delete cache
rm -rf /var/cache/apk/*

exit 0

