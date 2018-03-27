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

RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_ceph

rados_run="$CEPH_RADOS_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"
rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"
ceph_run="$CEPH_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x

$rados_run --pool="$CEPH_RBD_POOL" df &> /dev/null
if [ $? -ne 0 ]; then
	$rados_run mkpool "$CEPH_RBD_POOL" \
		|| _fail "failed to create pool"
	$ceph_run osd pool application enable "$CEPH_RBD_POOL" rbd \
		|| echo "ignoring failed application set"
fi

$rbd_run create --image-feature layering --size="${CEPH_RBD_IMAGE_MB}M" \
		--pool "$CEPH_RBD_POOL" "$CEPH_RBD_IMAGE" || exit 1
