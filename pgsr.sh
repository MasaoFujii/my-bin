#!/bin/sh

. pgcommon.sh

ACTDATA=$CURDIR/act
ACTCONF=$ACTDATA/postgresql.conf
ACTPORT=5432
ACTHBA=$ACTDATA/pg_hba.conf
ACTPREFIX=act
ACTARCH=$CURDIR/act.arh

SBYDATA=$CURDIR/sby
SBYCONF=$SBYDATA/postgresql.conf
SBYPORT=5433
SBYPREFIX=sby

PGBKP=$ACTDATA.bkp
TRIGGER=$CURDIR/trigger
RECOVERYCONF=$SBYDATA/recovery.conf

usage ()
{
	echo "$PROGNAME sets up streaming replication"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Default:"
	echo "  This utility sets up primary and standby servers"
	echo "  without the archive."
	echo ""
	echo "Options:"
	echo "  -a, --archive    uses the archive"
	echo "  -c, --conflict   creates standby query conflict"
	echo "  -p, --primary    sets up only primary server"
	echo "  -q, --quit       shuts down servers with fast mode"
	echo "  -s, --standby    sets up only standby server"
}

ONLYACT="FALSE"
ONLYSBY="FALSE"
USEARCH="FALSE"
QUITMODE="FALSE"
MKCONFLICT="FALSE"
while [ $# -gt 0 ]; do
	case "$1" in
		-a|--archive)
			USEARCH="TRUE";;
		-c|--conflict)
			MKCONFLICT="TRUE";;
		-h|--help|"-\?")
			usage
			exit 0;;
		-p|--primary)
			ONLYACT="TRUE";;
		-q|--quit)
			QUITMODE="TRUE";;
		-s|--standby)
			ONLYSBY="TRUE";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation

if [ $PGMAJOR -lt 90 ]; then
	elog "streaming replication is NOT supported in $($PGBIN/pg_config --version)"
fi

setup_primary ()
{
	pgsql_is_dead $ACTDATA

	pginitdb.sh $ACTDATA

	if [ "$USEARCH" = "TRUE" ]; then
		pgarch.sh $ACTDATA
	fi

	set_guc port $ACTPORT $ACTCONF
	set_guc log_line_prefix "'$ACTPREFIX '" $ACTCONF
	set_guc max_wal_senders 5 $ACTCONF
	set_guc wal_level hot_standby $ACTCONF

	echo "host replication all 0.0.0.0/0 trust" >> $ACTHBA
	echo "host replication all ::1/128   trust" >> $ACTHBA

	pgstart.sh -w $ACTDATA
}

setup_standby ()
{
	pgsql_is_dead $SBYDATA

	rm -rf $TRIGGER $SBYDATA

	pgbackup.sh $ACTDATA
	cp -r $PGBKP $SBYDATA

	set_guc port $SBYPORT $SBYCONF
	set_guc log_line_prefix "'$SBYPREFIX '" $SBYCONF
	set_guc hot_standby on $SBYCONF

	echo "standby_mode = 'on'" >> $RECOVERYCONF
	echo "primary_conninfo = 'host=localhost port=$ACTPORT'" >> $RECOVERYCONF
	echo "trigger_file = '$TRIGGER'" >> $RECOVERYCONF

	if [ "$USEARCH" = "TRUE" ]; then
		echo "restore_command = 'cp $ACTARCH/%f %p'" >> $RECOVERYCONF
	fi

	pgstart.sh $SBYDATA
}

if [ "$QUITMODE" = "TRUE" ]; then
	pgshutdown.sh -f $ACTDATA
	pgshutdown.sh -f $SBYDATA
	exit 0
fi

if [ "$MKCONFLICT" = "TRUE" ]; then
	pgsql_is_alive $ACTDATA
	pgsql_is_alive $SBYDATA

	TMPTBL=tmptable_$(date +%Y%m%d%H%M%S)

	$PGBIN/psql -p $ACTPORT -c "CREATE TABLE $TMPTBL (id int)"
	$PGBIN/psql -p $ACTPORT -c "INSERT INTO  $TMPTBL VALUES (1)"
	sleep 1

	$PGBIN/psql -p $SBYPORT -c "SELECT pg_sleep(60) FROM $TMPTBL" &
	PSQLPID=$!
	sleep 1

	$PGBIN/psql -p $ACTPORT -c "DELETE FROM $TMPTBL"
	$PGBIN/psql -p $ACTPORT -c "VACUUM $TMPTBL"

	exit 0
fi

if [ "$ONLYACT" = "TRUE" ]; then
	setup_primary
fi

if [ "$ONLYSBY" = "TRUE" ]; then
	setup_standby
fi

if [ "$ONLYACT" = "FALSE" -a "$ONLYSBY" = "FALSE" ]; then
	setup_primary
	setup_standby
fi
