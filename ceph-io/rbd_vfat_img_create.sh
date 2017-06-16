#!/bin/bash
#
# Copyright (C) SUSE LINUX GmbH 2017, all rights reserved.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 2.1 of the License, or
# (at your option) version 3.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.

# Create an RBD image $CEPH_RBD_IMAGE and format it as a vfat FS

RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

. "${RBD_USB_SRC}/rbd-usb.conf"

_rt_require_ceph

if [ "$(id -u)" != "0" ]; then
	_fail "$0 must be run as root for RBD mapping + mkfs"
fi

rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x

[ -b /dev/rbd0 ] && exit 1

$rbd_run create --size=${CEPH_RBD_IMAGE_MB}M "$CEPH_RBD_IMG" || exit 1

$rbd_run map "$CEPH_RBD_IMG" || exit 1

[ -b /dev/rbd0 ] || exit 1

/sbin/mkfs.vfat -n "Ceph" /dev/rbd0 || exit 1

$rbd_run unmap "$CEPH_RBD_IMG" || exit 1
