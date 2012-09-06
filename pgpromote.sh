#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME promotes PostgreSQL server."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [PGDATA]"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists
pgsql_is_alive

if [ $PGMAJOR -lt 82 ]; then
	elog "warm-standby is not supported"
fi

if [ $PGMAJOR -ge 91 ]; then
	$PGBIN/pg_ctl -D $PGDATA promote
else
	touch trigger
fi
