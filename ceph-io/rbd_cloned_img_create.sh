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

rbd_run="$CEPH_RBD_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"
# use arbitrary values for clone parent and snapshot names
rbd_img_parent="${CEPH_RBD_IMAGE}.src"
rbd_snap="mysnap"

set -x
$rbd_run create --size="2G" "$rbd_img_parent" || exit 1
$rbd_run snap create "${rbd_img_parent}@${rbd_snap}" || exit 1
$rbd_run snap protect "${rbd_img_parent}@${rbd_snap}" || exit 1
$rbd_run clone "${rbd_img_parent}@${rbd_snap}" "$CEPH_RBD_IMAGE" || exit 1
