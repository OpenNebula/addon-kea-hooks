#!/bin/sh

#
# Copyright (2019-2021) Petr Ospalý <pospaly@opennebula.io>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

set -ex

KEA_INSTALLPREFIX="${KEA_INSTALLPREFIX:-/usr/local}"

#
# functions
#

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

for i in \
    IKEA_PKG \
    KEA_VERSION \
    ALPINE_VERSION \
    ;
do
    _value=$(eval echo "\"\$${i}\"")
    if [ -z "$_value" ] ; then
        echo "ERROR: Variable '${i}' is unset" 1>&2
        exit 1
    fi
done

# here is expected that /build directory is provided as a bind mount for docker

if is_true USE_DISTRO_PACKAGE ; then
    # we need only the compiled hook binary when distribution version is used
    # and it is always under /usr
    tar cJf "/build/${IKEA_PKG}-${KEA_VERSION}-alpine${ALPINE_VERSION}.tar.xz" \
        /usr/lib/kea/hooks/opennebula-hooks.list \
        $(cat /usr/lib/kea/hooks/opennebula-hooks.list)
else
    # archive the complete software suite including all hooks
    tar cJf "/build/${IKEA_PKG}-${KEA_VERSION}-alpine${ALPINE_VERSION}.tar.xz" \
    	"${KEA_INSTALLPREFIX}/etc" \
    	"${KEA_INSTALLPREFIX}/include" \
    	"${KEA_INSTALLPREFIX}/lib" \
    	"${KEA_INSTALLPREFIX}/sbin" \
    	"${KEA_INSTALLPREFIX}/share" \
    	"${KEA_INSTALLPREFIX}/var" \
    	/etc/ld-musl-$(arch).path
fi

chown "${UID_GID:-$(id -u).}" \
    "/build/${IKEA_PKG}-${KEA_VERSION}-alpine${ALPINE_VERSION}.tar.xz"

exit 0

