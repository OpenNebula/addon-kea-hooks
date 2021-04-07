#!/bin/sh

#
# Copyright (2019) Petr Ospalý <petr@ospalax.cz>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

set -ex

#
# functions
#

on_exit()
{
    # this is the exit handler - I want to clean up as much as I can
    set +e

    # delete temporary working file(s)
    if [ -n "$_LOG_PIPE" ] ; then
        rm -f "$_LOG_PIPE"
    fi
}

# arg: <log_filename>
start_log()
{
    _logfile="$1"
    _LOG_PIPE="${BUILD_DIR}"/docker_log.pipe

    # create named pipe
    mknod "$_LOG_PIPE" p

    # connect tee to the pipe and let it write to the log and screen
    tee <"$_LOG_PIPE" -a "$_logfile" &

    # save stdout to fd 3 and force shell to write to the pipe
    exec 3>&1 >"$_LOG_PIPE"
}

end_log()
{
    # restore stdout for the shell and close fd 3
    exec >&3 3>&-
}

#
# main
#

trap 'on_exit 2>/dev/null' INT QUIT TERM EXIT

for i in \
    IKEA_TAG \
    KEA_VERSION \
    ALPINE_VERSION \
    KEA_INSTALLPREFIX \
    MAKE_JOBS \
    KEEP_BUILDBLOB \
    KEEP_BUILDDEPS \
    INSTALL_HOOKS \
    BUILD_DIR \
    USE_DISTRO_PACKAGE \
    ;
do
    _value=$(eval echo "\"\$${i}\"")
    if [ -z "$_value" ] ; then
        echo "ERROR: Variable '${i}' is unset" 1>&2
        exit 1
    fi
done

# start logging and printing
#
# workaround for: <failing command> | tee
# where the non-zero result code from the failing command is masked by tee or
# anything else on the end of the pipe...
start_log "${BUILD_DIR}/${IKEA_TAG}-${KEA_VERSION}-build.log"

# finally running the docker build...
docker build -t ${IKEA_TAG} \
    --build-arg ALPINE_VERSION \
    --build-arg KEA_VERSION \
    --build-arg KEA_INSTALLPREFIX \
    --build-arg MAKE_JOBS \
    --build-arg KEEP_BUILDBLOB \
    --build-arg KEEP_BUILDDEPS \
    --build-arg INSTALL_HOOKS \
    --build-arg USE_DISTRO_PACKAGE \
    .

# let's create all relevant tags
docker tag ${IKEA_TAG} ${IKEA_TAG}:${KEA_VERSION}
docker tag ${IKEA_TAG} ${IKEA_TAG}:${KEA_VERSION}-alpine${ALPINE_VERSION}

# stop logging and return stdout to what was before
end_log

exit 0

