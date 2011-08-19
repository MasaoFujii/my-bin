#!/bin/sh

. pgcommon

PGSTANDBY=$PGBIN/pg_standby

ACTDATA=$CURDIR/act
ACTCONF=$ACTDATA/postgresql.conf
ACTPORT=5432
ACTPREFIX=act

SBYDATA=$CURDIR/sby
SBYCONF=$SBYDATA/postgresql.conf
SBYPORT=5433
SBYPREFIX=sby

PGARCH=$ACTDATA.arh
PGBKP=$ACTDATA.bkp
TRIGGER=$CURDIR/trigger
RECOVERYCONF=$SBYDATA/recovery.conf

COPYMODE=false

usage ()
{
	echo "$PROGNAME configures warm-standby"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Description:"
	echo "  $PROGNAME creates warm-standby environement by using pg_standby as"
	echo "  restore_command by default."
	echo ""
	echo "Options:"
	echo "  -c, --copy      use 'cp' as restore_command (possible in 9.0 or later)"
}

while [ $# -gt 0 ]; do
	case "$1" in
		-c|--copy)
			COPYMODE=true;;
		-h|--help|"-\?")
			usage
			exit 0;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation
archiving_is_supported

if [ $PGMAJOR -lt 82 ]; then
	elog "warm-standby is not supported"
fi

if [ "$COPYMODE" = "true" ]; then
	if [ $PGMAJOR -lt 90 ]; then
		elog "copy mode (-c) requires v9.0 or later"
	fi
else
	if [ ! -f $PGSTANDBY ]; then
		elog "pg_standby must be installed"
	fi
fi

rm -rf $ACTDATA $SBYDATA $PGARCH $TRIGGER

pginitdb.sh $ACTDATA
pgarch $ACTDATA

set_guc port $ACTPORT $ACTCONF
set_guc log_line_prefix "'$ACTPREFIX '" $ACTCONF

pgstart.sh -w $ACTDATA
pgbackup $ACTDATA
cp -r $PGBKP $SBYDATA

set_guc port $SBYPORT $SBYCONF
set_guc log_line_prefix "'$SBYPREFIX '" $SBYCONF

if [ $PGMAJOR -ge 90 ]; then
	set_guc hot_standby on $SBYCONF
fi

if [ "$COPYMODE" = "true" ]; then
	echo "standby_mode = 'on'" >> $RECOVERYCONF
	echo "restore_command = 'cp $PGARCH/%f %p'" >> $RECOVERYCONF
	echo "trigger_file = '$TRIGGER'" >> $RECOVERYCONF
else
	RESTORECMD="$PGSTANDBY -t $TRIGGER -r 1 $PGARCH %f %p"
	echo "restore_command = '$RESTORECMD'" > $RECOVERYCONF
fi

pgstart.sh $SBYDATA
