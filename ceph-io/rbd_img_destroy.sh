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
rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x

$rbd_run rm --pool "$CEPH_RBD_POOL" "$CEPH_RBD_IMAGE"
