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

_rt_require_conf_dir SAMBA_SRC

creds_path="$(mktemp)" || _fail
trap "rm $creds_path" 0 1 2 3 15
[ -n "$CIFS_DOMAIN" ] && echo "domain=${CIFS_DOMAIN}" >> $creds_path
[ -n "$CIFS_USER" ] && echo "username=${CIFS_USER}" >> $creds_path
[ -n "$CIFS_PW" ] && echo "password=${CIFS_PW}" >> $creds_path
set -x

LD_LIBRARY_PATH="${SAMBA_SRC}/bin/shared:${SAMBA_SRC}/bin/shared/private"
${SAMBA_SRC}/bin/smbtorture -A $creds_path //${CIFS_SERVER}/${CIFS_SHARE} "$@" \
	|| _fail

set +x
