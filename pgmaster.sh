#!/bin/bash

. pgcommon.sh

ARCHIVE_MODE="FALSE"
SYNC_MODE="FALSE"
CHECKSUM=""

ACTDATA=act
update_pgdata $ACTDATA

usage ()
{
	echo "$PROGNAME sets up the master."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -a    enables WAL archiving"
	echo "  -A    sets Async mode (default)"
	echo "  -k    uses data page checksums"
	echo "  -S    sets Sync mode"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			ARCHIVE_MODE="TRUE";;
		-A)
			SYNC_MODE="FALSE";;
		-k)
			CHECKSUM="-k";;
		-S)
			SYNC_MODE="TRUE";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation
pgsql_is_dead
validate_replication
validate_datapage_checksums "$CHECKSUM"

pginitdb.sh $PGDATA $CHECKSUM

if [ "$ARCHIVE_MODE" = "TRUE" ]; then
	pgarch.sh $PGDATA
fi

set_guc port $PGPORT $PGCONF
set_guc log_line_prefix "'$PGDATA '" $PGCONF
set_guc max_wal_senders 4 $PGCONF
set_guc wal_level hot_standby $PGCONF
set_guc wal_keep_segments 32 $PGCONF

if [ "$SYNC_MODE" = "TRUE" ]; then
	set_guc synchronous_standby_names "'*'" $PGCONF
fi

echo "local replication all trust" >> $PGHBA
echo "host replication all 0.0.0.0/0 trust" >> $PGHBA
echo "host replication all ::1/128   trust" >> $PGHBA

pgstart.sh -w $PGDATA
