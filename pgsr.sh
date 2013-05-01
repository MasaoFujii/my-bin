#!/bin/bash

. pgcommon.sh

ARCHIVE_OPT=
SYNC_OPT=
SBYNUM=1
CASCADE=false
CHECKSUM=""

usage ()
{
	echo "$PROGNAME sets up the master and standby(s)."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -a          enables WAL archiving"
	echo "  -k          uses data page checksums"
	echo "  -n NUM      number of standbys (default: 1)"
	echo "  -A          sets Async mode (default)"
	echo "  -S          sets Sync mode"
	echo "  -C          sets up Cascade standby"
	echo "  --conflict  creates standby query conflict"
	echo ""
	echo "Note:"
	echo "  -n option specifies the number of only standbys"
	echo "  connecting directly to the master."
}

here_is_installation
validate_replication

make_conflict ()
{
	ACTDATA=act
	ACTPORT=5432
	ACTPSQL="$PGBIN/psql -p $ACTPORT -c"

	SBYDATA=sby1
	SBYPORT=5433
	SBYPSQL="$PGBIN/psql -p $SBYPORT -c"

	pgsql_is_alive $ACTDATA
	pgsql_is_alive $SBYDATA

	TMPTBL=tmptable_$(date +%Y%m%d%H%M%S)

	$ACTPSQL "CREATE TABLE $TMPTBL (id int)"
	$ACTPSQL "INSERT INTO  $TMPTBL VALUES (1)"
	sleep 1

	$SBYPSQL "SELECT pg_sleep(60) FROM $TMPTBL" &
	sleep 1

	$ACTPSQL "DELETE FROM $TMPTBL"
	$ACTPSQL "VACUUM $TMPTBL"

	exit 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			ARCHIVE_OPT="-a";;
		-k)
			CHECKSUM="-k";;
		-n)
			SBYNUM=$2
			if [ $SBYNUM -lt $SBYMIN ]; then
				elog "number of standbys must be >=$SBYMIN"
			fi
			shift;;
		-A)
			SYNC_OPT="";;
		-S)
			SYNC_OPT="-S";;
		-C)
			CASCADE=true
			validate_cascade_replication;;
		--conflict)
			make_conflict;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

validate_datapage_checksums "$CHECKSUM"

pgmaster.sh $ARCHIVE_OPT $SYNC_OPT $CHECKSUM
pgstandby.sh $ARCHIVE_OPT -n $SBYNUM

if [ "$CASCADE" = "true" ]; then
	pgstandby.sh $ARCHIVE_OPT -c sby1
fi
