/*
 * Copyright (C) SUSE LLC 2019, all rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) version 3.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 */

#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <grp.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

/* uids/gids string format is: <uid>[:gid[:sup_gid1:sup_gidn...]] */
static int
uids_gids_parse(char *uid_gids_str,
		uid_t *uid,
		gid_t *gid,
		size_t *sup_count,
		gid_t *sup_gids)
{
	char *save = NULL;
	char *endptr = NULL;
	char *tok = NULL;
	size_t sup_len = *sup_count;
	int i;

	tok = strtok_r(uid_gids_str, ":", &save);
	if (tok == NULL) {
		return -EINVAL;
	}
	*uid = strtol(tok, &endptr, 10);
	if ((endptr == tok) || (*endptr != '\0')) {
		return -EINVAL;
	}

	/* optional gids */
	*gid = -1;
	*sup_count = 0;
	for (i = 0; i < sup_len + 1; i++) {
		gid_t this_gid;

		tok = strtok_r(NULL, ":", &save);
		if (tok == NULL) {
			break;
		}

		this_gid = strtol(tok, &endptr, 10);
		if ((endptr == tok) || (*endptr != '\0')) {
			return -EINVAL;
		}

		if (i == 0) {
			/* primary gid */
			*gid = this_gid;
		} else {
			/* supplementary gid */
			sup_gids[i - 1] = this_gid;
			*sup_count = i;
		}
	}
	if ((*sup_count > 0) && (tok != NULL)) {
		return -E2BIG;
	}

	return 0;
}

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))
int
main(int argc, char **argv)
{
	uid_t uid = -1;
	gid_t gid = -1;
	gid_t sup_gids[10];
	size_t num_sup_gids = ARRAY_SIZE(sup_gids);
	int ret;

	if (argc < 3) {
		return EINVAL;
	}

	ret = uids_gids_parse(argv[1], &uid, &gid, &num_sup_gids, sup_gids);
	if (ret < 0) {
		fprintf(stderr, "failed to parse %s: %s\n",
			argv[1], strerror(-ret));
		return -ret;
	}

	if (num_sup_gids > 0) {
		ret = setgroups(num_sup_gids, sup_gids);
		if (ret < 0) {
			fprintf(stderr, "failed to setgroups: %s\n",
				strerror(errno));
			return errno;
		}
	}
	if (gid != -1) {
		ret = setgid(gid);
		if (ret < 0) {
			fprintf(stderr, "failed to setgid: %s\n",
				strerror(errno));
			return errno;
		}
	}
	ret = setuid(uid);
	if (ret < 0) {
		fprintf(stderr, "failed to setuid: %s\n", strerror(errno));
		return errno;
	}
	return execvp(argv[2], argv + 2);
}
