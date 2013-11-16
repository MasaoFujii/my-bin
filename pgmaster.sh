#!/bin/bash

. pgcommon.sh

ARCHIVE_OPT=
SYNC_MODE="FALSE"
CHECKSUM=""
XLOGDIR=""

ACTDATA=act
update_pgdata $ACTDATA

usage ()
{
cat <<EOF
$PROGNAME sets up the master.

Usage:
  $PROGNAME [OPTIONS]

Options:
  -a    enables WAL archiving
  -A    sets Async mode (default)
  -k    uses data page checksums
  -S    sets Sync mode
  -X    uses external XLOG directory
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			ARCHIVE_OPT="-a";;
		-A)
			SYNC_MODE="FALSE";;
		-k)
			CHECKSUM="-k";;
		-S)
			SYNC_MODE="TRUE";;
		-X)
			XLOGDIR="-X";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation
pgsql_is_dead
validate_replication
validate_datapage_checksums "$CHECKSUM"

pginitdb.sh $PGDATA $ARCHIVE_OPT $CHECKSUM $XLOGDIR
exit_on_error

set_guc port $PGPORT $PGCONF
set_guc log_line_prefix "'%t $PGDATA '" $PGCONF
set_guc max_wal_senders 4 $PGCONF
set_guc wal_level hot_standby $PGCONF
set_guc wal_keep_segments 32 $PGCONF

if [ "$SYNC_MODE" = "TRUE" ]; then
	set_guc synchronous_standby_names "'*'" $PGCONF
fi

echo "local replication all trust" >> $PGHBA
echo "host replication all 0.0.0.0/0 trust" >> $PGHBA
echo "host replication all ::1/128   trust" >> $PGHBA

	cat << EOF > $RECOVERYDONE
standby_mode = 'on'
primary_conninfo = 'port=5433 application_name=$PGDATA'
trigger_file = 'trigger0'
recovery_target_timeline = 'latest'
EOF

pgstart.sh -w $PGDATA
