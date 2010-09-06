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
	echo "  -p, --primary    sets up only primary server"
	echo "  -s, --standby    sets up only standby server"
}

ONLYACT="FALSE"
ONLYSBY="FALSE"
USEARCH="FALSE"
while [ $# -gt 0 ]; do
	case "$1" in
		-a|--archive)
			USEARCH="TRUE";;
		-h|--help|"-\?")
			usage
			exit 0;;
		-p|--primary)
			ONLYACT="TRUE";;
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
	pginitdb.sh $ACTDATA

	if [ "$USEARCH" = "TRUE" ]; then
		pgarch.sh $ACTDATA
	fi

	set_guc port $ACTPORT $ACTCONF
	set_guc log_line_prefix "'$ACTPREFIX '" $ACTCONF
	set_guc max_wal_senders 5 $ACTCONF
	set_guc wal_level hot_standby $ACTCONF

	echo "host replication all 0.0.0.0/0 trust" >> $ACTHBA

	pgstart.sh -w $ACTDATA
}

setup_standby ()
{
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
