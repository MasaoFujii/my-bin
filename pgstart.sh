#!/bin/sh

. pgcommon.sh

WAITOPT=

usage ()
{
	echo "$PROGNAME starts the postgres server"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -w       waits for the start to complete"
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		-w)
			WAITOPT="-w";;
		-*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
		*)
			update_pgdata "$1";;
	esac
	shift
done

check_here_is_installation
check_directory_exists $PGDATA "database cluster"

PgsqlMustNotRunning

${PGBIN}/pg_ctl $WAITOPT -D ${PGDATA} start
