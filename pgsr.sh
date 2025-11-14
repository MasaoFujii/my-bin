#!/bin/bash

. pgcommon.sh

ACT_OPT=
SBY_OPT=
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
  --slot      uses replication slot

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
			ACT_OPT="-a"
			SBY_OPT="-a $SBY_OPT";;
		-k)
			CHECKSUM="-k";;
		-n)
			SBYNUM=$2
			if [ $SBYNUM -lt $SBYMIN ]; then
				elog "number of standbys must be >=$SBYMIN"
			fi
			shift;;
		-r)
			ACT_OPT="-a"
			SBY_OPT="-r $SBY_OPT";;
		-A)
			SYNC_OPT="";;
		-S)
			SYNC_OPT="-S";;
		-C)
			CASCADE=true
			validate_cascade_replication;;
		--conflict)
			make_conflict;;
		--slot)
			SBY_OPT="--slot $SBY_OPT";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

validate_datapage_checksums "$CHECKSUM"

pgmaster.sh $ACT_OPT $SYNC_OPT $CHECKSUM
pgstandby.sh $SBY_OPT -n $SBYNUM

if [ "$CASCADE" = "true" ]; then
	pgstandby.sh $SBY_OPT -c sby1
fi
