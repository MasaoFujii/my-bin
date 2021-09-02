#!/bin/bash

. pgcommon.sh

ACTARCH_OPT=
SBYARCH_OPT=
SYNC_OPT=
SBYNUM=1
CASCADE=false
CHECKSUM=""

usage ()
{
cat <<EOF
$PROGNAME sets up the master and standby(s).

Usage:
  $PROGNAME [OPTIONS]

Options:
  -a          enables WAL archiving
  -k          uses data page checksums
  -n NUM      number of standbys (default: 1)
  -r          enables WAL archiving and restoring on shared archive
  -A          sets Async mode (default)
  -S          sets Sync mode
  -C          sets up Cascade standby
  --conflict  creates standby query conflict

Notes:
  -n option specifies the number of only standbys
  connecting directly to the master.
EOF
}

here_is_installation
validate_replication

make_conflict ()
{
	ACTDATA=data
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
			ACTARCH_OPT="-a"
			SBYARCH_OPT="-a $SBYARCH_OPT";;
		-k)
			CHECKSUM="-k";;
		-n)
			SBYNUM=$2
			if [ $SBYNUM -lt $SBYMIN ]; then
				elog "number of standbys must be >=$SBYMIN"
			fi
			shift;;
		-r)
			ACTARCH_OPT="-a"
			SBYARCH_OPT="-r $SBYARCH_OPT";;
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

pgmaster.sh $ACTARCH_OPT $SYNC_OPT $CHECKSUM
pgstandby.sh $SBYARCH_OPT -n $SBYNUM

if [ "$CASCADE" = "true" ]; then
	pgstandby.sh $SBYARCH_OPT -c sby1
fi
