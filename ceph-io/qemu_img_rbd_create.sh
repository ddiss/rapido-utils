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

# Create an RBD image $CEPH_RBD_IMAGE using qemu-img.
RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_ceph

qemu_img_run=`which qemu-img` || _fail "qemu-img not present in path"

set -x
$qemu_img_run create -f raw \
	"rbd:${CEPH_RBD_POOL}/${CEPH_RBD_IMAGE}:conf=${CEPH_CONF}" \
	"${CEPH_RBD_IMAGE_MB}M" \
	|| _fail "failed to create rbd img"
