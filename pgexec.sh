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
  $PROGNAME [OPTIONS] [QUERY]

Options:
  pgdata PGDATA        location of the database storage area

Query:
  location flush       pg_current_xlog_flush_location()
  location insert      pg_current_xlog_insert_location()
  location receive     pg_last_xlog_receive_location()
  location replay      pg_last_xlog_replay_location()
  location [write]     pg_current_xlog_location()
  replay [is_paused]   pg_is_xlog_replay_paused()
  replay pause         pg_xlog_replay_pause()
  replay resume        pg_xlog_replay_resume()
  replay timestamp     pg_last_xact_replay_timestamp()
  stat XXX             pg_stat_XXX view
  switch               pg_switch_xlog()
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		pgdata)
			update_pgdata "$2"
			shift;;
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

if [ "$QCMD" = "location" ]; then
	LSNFUNC="pg_current_xlog_location()"
	case "$ARGV1" in
		flush)
			LSNFUNC="pg_current_xlog_flush_location()";;
		insert)
			LSNFUNC="pg_current_xlog_insert_location()";;
		receive)
			LSNFUNC="pg_last_xlog_receive_location()";;
		replay)
			LSNFUNC="pg_last_xlog_replay_location()";;
	esac
	exec_query "SELECT lsn, CASE WHEN pg_is_in_recovery() THEN NULL ELSE pg_xlogfile_name(lsn) END walfile FROM ${LSNFUNC} lsn;"

elif [ "$QCMD" = "replay" ]; then
	REPLAYFUNC="pg_is_xlog_replay_paused()"
	case "$ARGV1" in
		pause)
			REPLAYFUNC="pg_xlog_replay_pause()";;
		resume)
			REPLAYFUNC="pg_xlog_replay_resume()";;
		timestamp)
			REPLAYFUNC="pg_last_xact_replay_timestamp()";;
	esac
	exec_query "SELECT ${REPLAYFUNC};"

elif [ "$QCMD" = "stat" ]; then
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
