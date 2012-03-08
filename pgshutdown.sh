#!/bin/sh

. pgcommon.sh

MODE="f"
SIGNAL="INT"
TARGETS="$PGDATA"
STOPALL=false

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
			STOPALL=true;;
		-s)
			MODE="s"
			SIGNAL="TERM";;
		-f)
			MODE="f"
			SIGNAL="INT";;
		-i)
			MODE="i"
			SIGNAL="QUIT";;
		-*)
			elog "invalid option: $1";;
		*)
			TARGETS="$1";;
	esac
	shift
done

if [ "$STOPALL" = "true" ]; then
	for PMPID in $(pgps.sh -1 -o ppid,pid | awk '$1 == 1 {print $2}'); do
		kill -$SIGNAL $PMPID
	done
	exit 0
fi

here_is_installation

for pgdata in $TARGETS; do
	update_pgdata "$pgdata"
	pgdata_exists

	$PGBIN/pg_ctl -D $PGDATA status > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		$PGBIN/pg_ctl -D $PGDATA -m$MODE stop
	fi
done
