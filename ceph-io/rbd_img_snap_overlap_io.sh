./bin/ceph osd map rbd
#!/bin/bash
#
# Copyright (C) SUSE LINUX GmbH 2018, all rights reserved.
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

rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x

# Needs to be run as root!
dev=$($rbd_run --pool "$CEPH_RBD_POOL" map "$CEPH_RBD_IMAGE")
[ -b $dev ] || exit 1

dd if=/dev/zero bs=1M count=1 of=${dev} || exit 1

$rbd_run --pool "$CEPH_RBD_POOL" snap create "${CEPH_RBD_IMAGE}@snap" || exit 1

dd if=/dev/urandom bs=1M count=1 of=${dev} || exit 1

$rbd_run --pool "$CEPH_RBD_POOL" unmap "$CEPH_RBD_IMAGE" || exit 1
