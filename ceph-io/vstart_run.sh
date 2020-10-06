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

# start a vstart Ceph cluster from CEPH_SRC
# XXX sudo is used for zram provisioning/mounting

RAPIDO_DIR="$(dirname $0)/../rapido"
RAPIDO_DIR="$(realpath $RAPIDO_DIR)"
. "${RAPIDO_DIR}/runtime.vars"

function _zram_mkfs_mount {
	local dev_size="$1"
	local mnt_path=$(realpath "$2")
	local mnt_owner="$3"
	local dev_mounted zram_dev zram_name

	[ -d "$mnt_path" ] || _fail "path $mnt_path not present"
	dev_mounted=$(awk '$2 ~ "^'"$mnt_path"'$" { print $1 }' /proc/mounts)
	if [ -z "$dev_mounted" ]; then
		zram_dev=$(sudo "${RAPIDO_DIR}/tools/zram_hot_add.sh" \
				"$dev_size" "$owner")
		[ -b "$zram_dev" ] || _fail "zram_dev ($zram_dev) didn't appear"
	else
		zram_name="${dev_mounted##*/}"
		[ -z "${zram_name##zram*}" ] \
			|| _fail "$mnt_path mounted with non-zram $dev_mounted"
		zram_dev="$dev_mounted"
		sudo umount "$zram_dev" || _fail "$mnt_path umount failed"
		# TODO avoid sudo: zram_hot_add.sh could set owner for sys paths
		pushd "/sys/devices/virtual/block/${zram_name}" || _fail
		echo 1 | sudo tee "reset" > /dev/null \
			|| _fail "failed to reset ${zram_name}"
		echo "$dev_size" | sudo tee "disksize" > /dev/null \
			|| _fail "failed to set ${zram_name} disksize"
		popd
	fi
	sudo /sbin/mkfs.xfs "$zram_dev" || _fail
	sudo mount -o discard "$zram_dev" "$mnt_path" || _fail
	sudo chown "$owner" "$mnt_path" || _fail
}

[ -z "$CEPH_SRC" ] && _fail "CEPH_SRC must be set for vstart"
[ -z "$BR_ADDR" ] && _fail "BR_ADDR must be set for vstart"

# Cmake vstarts now fail with the subnet suffix, so strip it
br_ip=${BR_ADDR%/*}

set -x	# want to be able to see what sudo is doing

cd "${CEPH_SRC}/build" || _fail "failed to enter CEPH_SRC build dir"
# use Ceph dir ownership for out and dev mounts
owner=$(stat --format="%U:%G" "${CEPH_SRC}/build") || _fail

_zram_mkfs_mount "1G" "${CEPH_SRC}/build/out" "$owner"
_zram_mkfs_mount "5G" "${CEPH_SRC}/build/dev" "$owner"

MON=1 OSD=3 MDS=1 MGR=1 RGW=0 ../src/vstart.sh -n -i $br_ip \
	--bluestore \
	|| _fail "CMake based vstart failed"
