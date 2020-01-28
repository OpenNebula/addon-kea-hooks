#!/bin/sh

set -ex

ALPINE_VERSION=${ALPINE_VERSION:-3.11}
KEA_VERSION=${KEA_VERSION:-1.6.1}
KEA_INSTALLPREFIX=/opt/one-appliance/kea
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

WORKDIR=$(git rev-parse --show-toplevel)

cd "$WORKDIR"

time make package

cd -

