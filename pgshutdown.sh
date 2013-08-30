#!/bin/bash

. pgcommon.sh

MODE="f"
SIGNAL="INT"
TARGETS="$PGDATA"
STOPALL=false
MAXWAIT=3600

usage ()
{
cat <<EOF
$PROGNAME shuts down PostgreSQL server.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -a         shuts down all servers
  -s         smart shutdown
  -f         fast shutdown (default)
  -i         immediate shutdown
  -t SECS    seconds to wait (default: 3600s)
EOF
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
		-t)
			MAXWAIT=$2
			shift;;
		-*)
			elog "invalid option: $1";;
		*)
			TARGETS="$1";;
	esac
	shift
done

pm_pids ()
{
	pgps.sh -1 -o ppid,pid | awk '$1 == 1 {print $2}'
}

if [ "$STOPALL" = "true" ]; then
	for PMPID in $(pm_pids); do
		kill -$SIGNAL $PMPID
	done

	printf "waiting for servers to shut down..."
	for ((i=0; i<$MAXWAIT; i++)); do
		if [ -z "$(pm_pids)" ]; then
			echo " done"
			exit 0
		fi
		printf "."
		sleep 1
	done
	echo " failed"
	exit 0
fi

here_is_installation

for pgdata in $TARGETS; do
	update_pgdata "$pgdata"
	pgdata_exists

	$PGBIN/pg_ctl -D $PGDATA status > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		$PGBIN/pg_ctl -D $PGDATA -m$MODE -t $MAXWAIT stop
	fi
done
