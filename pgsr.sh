#!/bin/bash

. pgcommon.sh

ARCHIVE_OPT=
SYNC_OPT=
SBYNUM=1

usage ()
{
	echo "$PROGNAME sets up the master and standby(s)."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -a        enables WAL archiving"
	echo "  -n NUM    number of standbys (default: 1)"
	echo "  -A        sets Async mode (default)"
	echo "  -S        sets Sync mode"
	echo "  -q        shuts down master and standby(s)"
	echo "  -C        creates standby query conflict"
}

here_is_installation
if [ $PGMAJOR -lt 90 ]; then
	elog "streaming replication is NOT supported in $($PGBIN/pg_config --version)"
fi

quit_servers ()
{
	pgshutdown.sh -f $ACTDATA
	for SBYID in $(seq $SBYMIN $SBYMAX); do
		$PGBIN/pg_ctl -D $SBYDATA$SBYID status > /dev/null
		if [ $? -eq 0 ]; then
			pgshutdown.sh -f $SBYDATA$SBYID
		fi
	done
	exit 0
}

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
		-q)
			quit_servers;;
		-C)
			make_conflict;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

pgmaster.sh $ARCHIVE_OPT $SYNC_OPT
pgstandby.sh $ARCHIVE_OPT -n $SBYNUM
