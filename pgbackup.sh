#!/bin/sh

. pgcommon.sh

usage ()
{
    echo "$PROGNAME creates a base backup"
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [PGDATA]"
    echo ""
		echo "Description:"
		echo "  This utility creates a base backup of PGDATA."
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		-*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
		*)
			update_pgdata "$1";;
	esac
	shift
done

check_here_is_installation
check_archiving_is_supported
check_directory_exists $PGDATA "database cluster"

PgsqlMustRunning

rm -rf $PGDATABKP

if [ ${PGMAJOR} -ge 84 ]; then
	$PGBIN/psql -c "SELECT pg_start_backup('pgbackup', true)" template1
else
	$PGBIN/psql -c "CHECKPOINT; SELECT pg_start_backup('pgbackup', true)" template1
fi

rsync -a --exclude=postmaster.pid --exclude=pg_xlog $PGDATA/ $PGDATABKP
$PGBIN/psql -c "SELECT pg_stop_backup()" template1

mkdir -p $PGDATABKP/pg_xlog/archive_status
