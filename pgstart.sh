#!/bin/sh

. pgcommon

OPT=

usage ()
{
	echo "$PROGNAME starts PostgreSQL server."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -w    waits for the start to complete"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-w)
			OPT="-w";;
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

$PGBIN/pg_ctl $OPT -D $PGDATA start
