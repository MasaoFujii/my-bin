#!/bin/sh

. pgcommon.sh

usage ()
{
cat <<EOF
$PROGNAME creates a base backup.

Usage:
  $PROGNAME [PGDATA]
EOF
}

pg_start_backup ()
{
	if [ $PGMAJOR -ge 150 ]; then
		echo "SET synchronous_commit TO local;"
		echo "SELECT pg_backup_start('pgbackup.sh', true);"
	elif [ $PGMAJOR -ge 91 ]; then
		echo "SET synchronous_commit TO local;"
		echo "SELECT pg_start_backup('pgbackup.sh', true);"
	elif [ $PGMAJOR -ge 84 ]; then
		echo "SELECT pg_start_backup('pgbackup.sh', true);"
	else
		echo "CHECKPOINT;"
		echo "SELECT pg_start_backup('pgbackup.sh');"
	fi
}

pg_stop_backup ()
{
	if [ $PGMAJOR -ge 150 ]; then
		cat <<EOF
SET synchronous_commit TO local;
SELECT
  set_config('backup.labelfile', labelfile, false) labelfile,
  set_config('backup.spcmapfile', spcmapfile, false) spcmapfile
FROM pg_backup_stop();
\pset tuples_only on
\pset format unaligned
\o ${PGDATABKP}/backup_label
SELECT * FROM current_setting('backup.labelfile');
\o ${PGDATABKP}/tablespace_map
SELECT * FROM current_setting('backup.spcmapfile');
EOF
	elif [ $PGMAJOR -ge 91 ]; then
		echo "SET synchronous_commit TO local;"
		echo "SELECT pg_stop_backup();"
	else
		echo "SELECT pg_stop_backup();"
fi
}

backup_script ()
{
	pg_start_backup
	echo "\\! pgrsync.sh -b $PGDATA $PGDATABKP"
	pg_stop_backup
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
validate_archiving
pgdata_exists
pgsql_is_alive

prepare_psql
backup_script | $PSQL -d template1
