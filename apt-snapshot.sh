# SPDX-FileCopyrightText: (c) 2025 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

#!/bin/bash

set -ex

# ubuntu snapshots are limited for arm64 on focal, but they do work.
# we dicovered that an 'apt-get update' must occur prior to adding
# the snapshot modifier, otherwise it will error "Snapshots are not
# supported".

# since this is used for multilayer docker images, it's helpful
# to be able to clear apt cache at the end of the stage. note that
# 'rm -rf /var/lib/apt/lists/*' will remove lists that will break
# 'apt-update' on arm64, producing the error "Snapshots are not
# supported". It's resolved by restoring the original apt sources,
# disabling the snapshot sources, and then performing an apt-update.
#
# So maybe don't do that. Don't clear /var/lib/apt/lists/* on arm64.
# It only saves a few kb.

if [ -z "${UBUNTU_SNAPSHOT}" ]; then
    echo "UBUNTU_SNAPSHOT environment variable not set. No snapshot will be configured."
    exit 0
fi

# temporarily disable the apt.conf variable that enables snapshots for all archives
rm -f /etc/apt/apt.conf.d/50snapshot

# disable ubuntu snapshot to first update ubuntu archive lists, which enables snapshots
# then disable the system sources.list
if [ -f /etc/apt/sources.list.d/ubuntu-snapshot.list ]; then
    mv -f /etc/apt/sources.list.d/ubuntu-snapshot.list /etc/apt/sources.list.d/ubuntu-snapshot.list.disabled
fi
# enable system apt sources
if [ -f /etc/apt/sources.list.disabled ]; then
    mv -f /etc/apt/sources.list.disabled /etc/apt/sources.list
fi
apt-get update -q

# updated certificates are required to access the archive repos
# install the version from focal 20.04LTS
if ! dpkg -s ca-certificates >/dev/null 2>&1; then
    apt-get install -y -q --no-install-recommends \
        openssl=1.1.1f-1ubuntu2.24 \
        libssl1.1=1.1.1f-1ubuntu2 \
        ca-certificates=20240203~20.04.1
fi

# set up snapshot sources
if [ -f /etc/apt/sources.list.d/ubuntu-snapshot.list.disabled ]; then
    mv -f /etc/apt/sources.list.d/ubuntu-snapshot.list.disabled /etc/apt/sources.list.d/ubuntu-snapshot.list
else
    if [ "$(uname -m)" = "x86_64" ]; then
        cat <<EOF > /etc/apt/sources.list.d/ubuntu-snapshot.list
deb [snapshot=${UBUNTU_SNAPSHOT}] http://archive.ubuntu.com/ubuntu/ focal main restricted
deb [snapshot=${UBUNTU_SNAPSHOT}] http://archive.ubuntu.com/ubuntu/ focal-updates main restricted
deb [snapshot=${UBUNTU_SNAPSHOT}] http://archive.ubuntu.com/ubuntu/ focal universe
deb [snapshot=${UBUNTU_SNAPSHOT}] http://archive.ubuntu.com/ubuntu/ focal-updates universe
deb [snapshot=${UBUNTU_SNAPSHOT}] http://security.ubuntu.com/ubuntu focal-security main restricted
EOF
    else
        cat <<EOF > /etc/apt/sources.list.d/ubuntu-snapshot.list
deb [snapshot=${UBUNTU_SNAPSHOT}] http://ports.ubuntu.com/ubuntu-ports/ focal main restricted
deb [snapshot=${UBUNTU_SNAPSHOT}] http://ports.ubuntu.com/ubuntu-ports/ focal-updates main restricted
deb [snapshot=${UBUNTU_SNAPSHOT}] http://ports.ubuntu.com/ubuntu-ports/ focal universe
deb [snapshot=${UBUNTU_SNAPSHOT}] http://ports.ubuntu.com/ubuntu-ports/ focal-updates universe
deb [snapshot=${UBUNTU_SNAPSHOT}] http://ports.ubuntu.com/ubuntu-ports/ focal-security main restricted
EOF
    fi
fi

# set the apt.conf variable that enables snapshots for all archives that support them
echo "APT::Snapshot \"${UBUNTU_SNAPSHOT}\";" | tee /etc/apt/apt.conf.d/50snapshot

# disable system apt sources
if [ -f /etc/apt/sources.list ]; then
    mv -f /etc/apt/sources.list /etc/apt/sources.list.disabled
fi

# update snapshot lists
apt-get update -q
