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

# create a "bootstrap-osd" key and append it to the existing ceph keyring

RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_ceph

ceph_run="$CEPH_BIN -c $CEPH_CONF -k $CEPH_KEYRING --user $CEPH_USER"
new_keyring="$(mktemp)" || _fail "failed to create tmp file"

cat $CEPH_KEYRING > $new_keyring

set -x

$ceph_run auth get-or-create client.bootstrap-osd osd 'allow *' mon 'allow *' \
	|| _fail "failed to create key for client.bootstrap-osd"
$ceph_run auth export client.bootstrap-osd >> $new_keyring

mv $new_keyring $CEPH_KEYRING
