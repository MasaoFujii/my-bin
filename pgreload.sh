#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME reloads the postgres configuration file"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [PGDATA]"
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
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

$PGBIN/pg_ctl -D $PGDATA reload
