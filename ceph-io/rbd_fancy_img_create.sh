#!/bin/bash
#
# Copyright (C) SUSE LLC 2020, all rights reserved.
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

# CEPH[_RBD]_BIN aren't set by rapido
CEPH_RBD_BIN="$(dirname $CEPH_CONF_BIN)/rbd"
CEPH_BIN="$(dirname $CEPH_CONF_BIN)/ceph"
rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"
ceph_run="$CEPH_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x

$ceph_run osd pool get "$CEPH_RBD_POOL" size &> /dev/null
if [ $? -ne 0 ]; then
	$ceph_run osd pool create "$CEPH_RBD_POOL" 128 \
		|| _fail "failed to create pool"
	$rbd_run pool init "$CEPH_RBD_POOL" \
		|| _fail "failed to init rbd pool"
fi

$rbd_run create --image-feature layering,object-map,exclusive-lock \
		--stripe-unit 8192 \
		--stripe-count 40 \
		--size="${CEPH_RBD_IMAGE_MB}M" \
		--pool "$CEPH_RBD_POOL" "$CEPH_RBD_IMAGE" || exit 1
