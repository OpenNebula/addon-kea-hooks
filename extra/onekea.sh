#!/bin/sh

set -ex

ALPINE_VERSION=${ALPINE_VERSION:-3.13}
KEA_VERSION=${KEA_VERSION:-1.8.2}
#KEA_INSTALLPREFIX=/opt/one-appliance/kea
USE_DISTRO_PACKAGE=yes
KEA_INSTALLPREFIX=/usr # using the distribution version which is under /usr
MAKE_JOBS="${MAKE_JOBS:-4}"
IKEA_TAG=onekea
IKEA_IMG=onekea-image
IKEA_PKG=onekea
INSTALL_HOOKS=yes

export ALPINE_VERSION
export KEA_VERSION
export KEA_INSTALLPREFIX
export MAKE_JOBS
export IKEA_TAG
export IKEA_IMG
export IKEA_PKG
export INSTALL_HOOKS
export USE_DISTRO_PACKAGE

WORKDIR=$(git rev-parse --show-toplevel)

cd "$WORKDIR"

time make package

cd -

