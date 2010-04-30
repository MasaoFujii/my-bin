#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME shuts down the postgres server"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Default:"
	echo "  This utility performs a smart shutdown"
	echo ""
	echo "Options:"
	echo "  -f, --fast        performs a fast shutdown"
	echo "  -i, --immediate   performs an immediate shutdown"
	echo "  -s, --smart       performs a smart shutdown"
}

SHUTDOWN_MODE="s"
while [ $# -gt 0 ]; do
	case "$1" in
		-f|--fast)
			SHUTDOWN_MODE="f";;
		-h|--help|"-\?")
			usage
			exit 0;;
		-i|--immediate)
			SHUTDOWN_MODE="i";;
		-s|--smart)
			SHUTDOWN_MODE="s";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgsql_is_alive

$PGBIN/pg_ctl -D $PGDATA -m$SHUTDOWN_MODE stop
