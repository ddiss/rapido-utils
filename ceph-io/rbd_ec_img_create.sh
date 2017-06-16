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

# Create an RBD image $CEPH_RBD_IMAGE, using the "ec" pool for data, and
# "rbd" pool for metadata.
RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_ceph

rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x

$CEPH_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER \
	osd pool set ec allow_ec_overwrites true \
	|| _fail "failed to enable allow_ec_overwrites"

# assume "vstart -e" ec and rbd pools
$rbd_run --data-pool ec --journal-pool rbd create \
	 --image-feature layering,data-pool \
	 --size=${CEPH_RBD_IMAGE_MB}M $CEPH_RBD_IMAGE || exit 1
