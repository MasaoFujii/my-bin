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
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

if [ ! -d $PGDATA ]; then
	pginitdb.sh
fi

pgsql_is_dead

$PGBIN/pg_ctl $WAITOPT -D $PGDATA start
