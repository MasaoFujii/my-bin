#!/bin/bash

. pgcommon.sh

INITDB_OPT=
SYNC_MODE="FALSE"

usage ()
{
cat <<EOF
$PROGNAME sets up the master.

Usage:
  $PROGNAME [OPTIONS]

Options:
  -a          enables WAL archiving
  -A          sets Async mode (default)
  -k          uses data page checksums
  -S          sets Sync mode
  -X          uses external XLOG directory
  --no-tune   does NOT use auto tuning
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			INITDB_OPT="-a $INITDB_OPT";;
		-A)
			SYNC_MODE="FALSE";;
		-k)
			INITDB_OPT="-k $INITDB_OPT";;
		-S)
			SYNC_MODE="TRUE";;
		-X)
			INITDB_OPT="-X $INITDB_OPT";;
		--no-tune)
			INITDB_OPT="--no-tune $INITDB_OPT";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation
pgsql_is_dead
validate_replication
validate_datapage_checksums "$CHECKSUM"

pginitdb.sh $INITDB_OPT $PGDATA
exit_on_error

set_guc port $PGPORT $PGCONF
set_guc max_wal_senders 4 $PGCONF

if [ $PGMAJOR -ge 94 ]; then
	set_guc max_replication_slots 4 $PGCONF
fi

if [ $PGMAJOR -ge 93 ]; then
	set_guc wal_sender_timeout 0 $PGCONF
else
	set_guc replication_timeout 0 $PGCONF
fi

if [ $PGMAJOR -ge 130 ]; then
	set_guc wal_keep_size "'512MB'" $PGCONF
else
	set_guc wal_keep_segments 32 $PGCONF
fi

if [ "$SYNC_MODE" = "TRUE" ]; then
	set_guc synchronous_standby_names "'*'" $PGCONF
fi

echo "local replication all trust" >> $PGHBA
echo "host replication all 0.0.0.0/0 trust" >> $PGHBA
echo "host replication all ::1/128   trust" >> $PGHBA

if [ $PGMAJOR -lt 120 ]; then
	cat << EOF > $RECOVERYDONE
standby_mode = 'on'
primary_conninfo = 'port=5433 application_name=$PGDATA'
trigger_file = 'trigger0'
recovery_target_timeline = 'latest'
EOF
fi

pgstart.sh -w $PGDATA
