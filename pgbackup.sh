#!/bin/sh

. pgcommon.sh

usage ()
{
    echo "$PROGNAME creates a base backup."
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [PGDATA]"
    echo ""
		echo "Description:"
		echo "  This utility creates a base backup of PGDATA."
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
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
archiving_is_supported
pgdata_exists
pgsql_is_alive

PSQL="$PGBIN/psql -p $PGPORT -c"

rm -rf $PGDATABKP

if [ $PGMAJOR -ge 91 ]; then
	$PSQL "SET synchronous_commit TO local; SELECT pg_start_backup('pgbackup', true)" template1
elif [ $PGMAJOR -ge 84 ]; then
	$PSQL "SELECT pg_start_backup('pgbackup', true)" template1
else
	$PSQL "CHECKPOINT; SELECT pg_start_backup('pgbackup')" template1
fi

pgrsync.sh -b $PGDATA $PGDATABKP

if [ $PGMAJOR -ge 91 ]; then
	$PSQL "SET synchronous_commit TO local; SELECT pg_stop_backup()" template1
else
	$PSQL "SELECT pg_stop_backup()" template1
fi

mkdir -p $PGDATABKP/pg_xlog/archive_status
