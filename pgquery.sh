#!/bin/sh

. pgcommon.sh

QCMD=
ARGV1=
ARGV2=

usage ()
{
cat <<EOF
$PROGNAME executes a query on PostgreSQL server.

Usage:
  $PROGNAME [QUERY]

Query:
  stat XXX     pg_stat_XXX view
  switch       pg_switch_xlog function
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			if [ -z "$QCMD" ]; then
				QCMD="$1"
			elif [ -z "$ARGV1" ]; then
				ARGV1="$1"
			elif [ -z "$ARGV2" ]; then
				ARGV2="$1"
			fi
			;;
	esac
	shift
done

here_is_installation
pgdata_exists
pgsql_is_alive

prepare_psql

exec_query ()
{
	QUERY="$1"
	cat <<EOF | $PSQL
\x auto
\set ECHO all
$QUERY
EOF
}

if [ "$QCMD" = "stat" ]; then
	PGSTATVIEW="pg_stat_${ARGV1}"
	if [ -z "$ARGV1" ]; then
		PGSTATVIEW="pg_stat_activity"
	fi
	exec_query "SELECT * FROM ${PGSTATVIEW};"

elif [ "$QCMD" = "switch" ]; then
	exec_query "SELECT lsn, pg_xlogfile_name(lsn) walfile FROM pg_switch_xlog() lsn;"

else
	exec_query "SELECT * FROM pg_stat_activity;"
fi
