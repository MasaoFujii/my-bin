#!/bin/sh

. pgcommon.sh

MODE="normal"	# normal, start or stop

usage ()
{
    echo "$PROGNAME creates a base backup."
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [OPTIONS] [PGDATA]"
    echo ""
		echo "Options:"
		echo "  --start    executes only pg_start_backup"
		echo "  --stop     executes only pg_stop_backup"
}

pg_start_backup ()
{
	if [ $PGMAJOR -ge 91 ]; then
		$PSQL "SET synchronous_commit TO local; SELECT pg_start_backup('pgbackup.sh', true)" template1
	elif [ $PGMAJOR -ge 84 ]; then
		$PSQL "SELECT pg_start_backup('pgbackup.sh', true)" template1
	else
		$PSQL "CHECKPOINT; SELECT pg_start_backup('pgbackup.sh')" template1
	fi
}

pg_stop_backup ()
{
	if [ $PGMAJOR -ge 91 ]; then
		$PSQL "SET synchronous_commit TO local; SELECT pg_stop_backup()" template1
	else
		$PSQL "SELECT pg_stop_backup()" template1
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
ValidateArchiving
pgdata_exists
pgsql_is_alive

PSQL="$PGBIN/psql -p $PGPORT -c"

case "$MODE" in
	normal)
		normal_backup;;
	start)
		pg_start_backup;;
	stop)
		pg_stop_backup;;
esac
