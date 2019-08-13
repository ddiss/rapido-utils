#!/bin/bash
#
# Copyright (C) SUSE LINUX GmbH 2019, all rights reserved.
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
RAPIDO_DIR="$(realpath $RAPIDO_DIR)"
. "${RAPIDO_DIR}/runtime.vars"

function _uml_is_running
{
	local vm_num=$1

	pgrep -a linux|grep rapido.vm_num=${vm_num} > /dev/null && echo "1"
}

function _uml_start
{
	local vm_num=$1

	[ -f "$DRACUT_OUT" ] \
	   || _fail "no initramfs image at ${DRACUT_OUT}. Run \"cut_X\" script?"

	if [ -z "$vm_num" ] || [ $vm_num -lt 1 ] || [ $vm_num -gt 2 ]; then
		_fail "a maximum of two network connected VMs are supported"
	fi

	# XXX rapido.conf VM parameters are pretty inconsistent and confusing
	# moving to a VM${vm_num}_MAC_ADDR or ini style config would make sense
	local qemu_netdev=""
	local kern_ip_addr=""
	if [ -n "$(_rt_xattr_vm_networkless_get ${DRACUT_OUT})" ]; then
		# this image doesn't require network access
		kern_ip_addr="none"
		qemu_netdev=""
	else
		eval local mac_addr='$MAC_ADDR'${vm_num}
		eval local tap='$TAP_DEV'$((vm_num - 1))
		[ -n "$tap" ] \
			|| _fail "TAP_DEV$((vm_num - 1)) not configured"
		eval local is_dhcp='$IP_ADDR'${vm_num}'_DHCP'
		if [ "$is_dhcp" = "1" ]; then
			kern_ip_addr="dhcp"
		else
			eval local hostname='$HOSTNAME'${vm_num}
			[ -n "$hostname" ] \
				|| _fail "HOSTNAME${vm_num} not configured"
			eval local ip_addr='$IP_ADDR'${vm_num}
			[ -n "$ip_addr" ] \
				|| _fail "IP_ADDR${vm_num} not configured"
			kern_ip_addr="${ip_addr}:::255.255.255.0:${hostname}"
		fi
		qemu_netdev="eth0=tuntap,${tap},${mac_addr}"
	fi

	# cut_ script may have specified some parameters for qemu
	local qemu_more_args="$qemu_netdev"

	local vm_resources="$(_rt_xattr_vm_resources_get ${DRACUT_OUT})"
	[ -z "$vm_resources" ] \
		|| _fail "explicit VM resources not supported by UML runner"
	vm_resources="mem=512m"

	# rapido.conf might have specified a shared folder for qemu
	[ -z "$VIRTFS_SHARE_PATH" ] \
		|| _fail "UML not compatible with VIRTFS_SHARE_PATH"

	[ -x "${KERNEL_SRC}/linux" ] \
	   || _fail "no UML executable at ${KERNEL_SRC}/linux. Build needed?"

	set -x

	#	umid=rapido_uml${vm_num} \
	${KERNEL_SRC}/linux $vm_resources \
		initrd=$DRACUT_OUT \
		rapido.vm_num=${vm_num} ip=${kern_ip_addr} \
		rd.systemd.unit=emergency \
		rd.shell=1 rd.lvm=0 rd.luks=0 \
		uml_dir=${RAPIDO_DIR}/initrds $qemu_netdev
	exit $?
}

[ -z "$(_uml_is_running 1)" ] && _uml_start 1
[ -z "$(_uml_is_running 2)" ] && _uml_start 2
# _uml_start exits when done, so we only get here if none were started
_fail "Currently Rapido only supports a maximum of two VMs"
