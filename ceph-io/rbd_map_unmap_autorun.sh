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

if [ ! -f /vm_autorun.env ]; then
	echo "Error: autorun scripts must be run from within an initramfs VM"
	exit 1
fi

[ -f /usr/lib/udev/rules.d/50-rbd.rules ] || _fatal "rbd udev rule not found"

function _rbd_map()
{
	local mon_address="$1"
	local user="$2"
	local secret="$3"
	local pool="$4"
	local img="$5"

	echo -n "$mon_address name=${user},secret=${secret} \
		 $pool $img -" \
		 > /sys/bus/rbd/add || _fatal "RBD map failed"
	udevadm settle || _fatal

	[ -b "/dev/rbd/${pool}/${img}" ] || _fatal "block device did not appear"

	echo "/dev/rbd/${pool}/${img}"
}

function _rbd_unmap()
{
	local dev="$1"

	[ -b "$dev" ] || _fatal "invalid unmap block device: $dev"

	dev="$(readlink -n $dev)"
	num="${dev##/dev/rbd}"

	echo -n "$num" > /sys/bus/rbd/remove || _fatal "RBD unmap failed"
	udevadm settle || _fatal

	[ -b "$dev" ] && _fatal "block device did not disappear"
}

#### start udevd, otherwise rbd hangs in wait_for_udev_add()
ps -eo args | grep -v grep | grep /usr/lib/systemd/systemd-udevd \
	|| /usr/lib/systemd/systemd-udevd --daemon

##### map rbd device
_ini_parse "/etc/ceph/keyring" "client.${CEPH_USER}" "key"
[ -z "$key" ] && _fatal "client.${CEPH_USER} key not found in keyring"
if [ -z "$CEPH_MON_NAME" ]; then
	# pass global section and use mon_host
	_ini_parse "/etc/ceph/ceph.conf" "global" "mon_host"
	MON_ADDRESS="$mon_host"
else
	_ini_parse "/etc/ceph/ceph.conf" "mon.${CEPH_MON_NAME}" "mon_addr"
	MON_ADDRESS="$mon_addr"
fi

_rbd_map "$MON_ADDRESS" "$CEPH_USER" "$key" "$CEPH_RBD_POOL" "$CEPH_RBD_IMAGE" \
	|| _fatal "failed to map"
