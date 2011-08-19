#!/bin/sh

. pgcommon

MODE="f"
TARGETS=""

usage ()
{
	echo "$PROGNAME shuts down PostgreSQL server."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -a    shuts down all servers"
	echo "  -s    smart shutdown"
	echo "  -f    fast shutdown (default)"
	echo "  -i    immediate shutdown"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			TARGETS=$(find_all_pgdata);;
		-s)
			MODE="s";;
		-f)
			MODE="f";;
		-i)
			MODE="i";;
		-*)
			elog "invalid option: $1";;
		*)
			TARGETS="$1";;
	esac
	shift
done

here_is_installation

for pgdata in $TARGETS; do
	update_pgdata "$pgdata"

	$PGBIN/pg_ctl -D $PGDATA status > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		$PGBIN/pg_ctl -D $PGDATA -m$MODE stop
	fi
done
