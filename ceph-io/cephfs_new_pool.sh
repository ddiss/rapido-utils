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

# Create a new RADOS pool new_pool and add it as a data pool to the
# default vstart filesystem cephfs_a.

RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_ceph

vstart_default_fs="cephfs_a"
new_pool="new_pool"

ceph_run="$CEPH_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"

set -x
$ceph_run fs ls | grep -q "$vstart_default_fs" \
	|| _fail "$vstart_default_fs filesystem not present"

$ceph_run osd pool create "$new_pool" 128 || _fail "failed to create new pool"
$ceph_run fs add_data_pool "$vstart_default_fs" "$new_pool" \
	|| _fail "failed to add new_pool to $vstart_default_fs"


