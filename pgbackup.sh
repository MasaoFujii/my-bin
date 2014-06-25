#!/bin/sh

. pgcommon.sh

MODE="normal"	# normal, start or stop

usage ()
{
cat <<EOF
$PROGNAME creates a base backup.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  --start    executes only pg_start_backup
  --stop     executes only pg_stop_backup
EOF
}

pg_start_backup ()
{
	if [ $PGMAJOR -ge 91 ]; then
		$PSQL "SET synchronous_commit TO local; SELECT pg_start_backup('pgbackup.sh', true)"
	elif [ $PGMAJOR -ge 84 ]; then
		$PSQL "SELECT pg_start_backup('pgbackup.sh', true)"
	else
		$PSQL "CHECKPOINT; SELECT pg_start_backup('pgbackup.sh')"
	fi
}

pg_stop_backup ()
{
	if [ $PGMAJOR -ge 91 ]; then
		$PSQL "SET synchronous_commit TO local; SELECT pg_stop_backup()"
	else
		$PSQL "SELECT pg_stop_backup()"
fi
}

normal_backup ()
{
	pg_start_backup
	pgrsync.sh -b $PGDATA $PGDATABKP
	pg_stop_backup
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		--start)
			MODE="start";;
		--stop)
			MODE="stop";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
validate_archiving
pgdata_exists
pgsql_is_alive

prepare_psql
PSQL="$PSQL -d template1 -c"

case "$MODE" in
	normal)
		normal_backup;;
	start)
		pg_start_backup;;
	stop)
		pg_stop_backup;;
esac
