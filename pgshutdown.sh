#!/bin/sh

. pgcommon.sh

MODE="f"

usage ()
{
	echo "$PROGNAME shuts down PostgreSQL server."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -f    fast shutdown (default)"
	echo "  -i    immediate shutdown"
	echo "  -s    smart shutdown"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-f)
			MODE="f";;
		-i)
			MODE="i";;
		-s)
			MODE="s";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgsql_is_alive

$PGBIN/pg_ctl -D $PGDATA -m$MODE stop
