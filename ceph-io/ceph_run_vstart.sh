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

RAPIDO_DIR="`dirname $0`/../rapido"
. "${RAPIDO_DIR}/runtime.vars"

[ -z "$CEPH_SRC" ] && _fail "CEPH_SRC must be set for vstart"
[ -z "$BR_ADDR" ] && _fail "BR_ADDR must be set for vstart"

# Cmake vstarts now fail with the subnet suffix, so strip it
br_ip=${BR_ADDR%/*}

if [ -f "${CEPH_SRC}/build/CMakeCache.txt" ]; then
	cd ${CEPH_SRC}/build
	../src/vstart.sh -n -i $br_ip --mon_num 1 --osd_num 3 --mds_num 0 \
		--mgr_num 1 \
		|| _fail "CMake based vstart failed"
else
	cd ${CEPH_SRC}/src
	./vstart.sh -n -i $br_ip --mon_num 1 --osd_num 4 --mds_num 0 \
		|| _fail "autotools based vstart failed"
fi
