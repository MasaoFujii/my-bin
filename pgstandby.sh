#!/bin/bash

. pgcommon.sh

ACTPORT=5432
ACTARCH=$CURDIR/act.arh
ACTBKP=$CURDIR/act.bkp

SBYID=0
SBYNUM=1
STARTED=0

SNDDATA=
SNDPORT=

ARCHIVE_MODE="FALSE"

usage ()
{
	echo "$PROGNAME sets up the standby(s)."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -a         enables WAL archiving"
	echo "  -c SENDER  sets up the cascade standby"
	echo "  -n NUM     number of standbys (default: 1)"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			ARCHIVE_MODE="TRUE";;
		-c)
			SNDDATA=$2
			shift;;
		-n)
			SBYNUM=$2
			if [ $SBYNUM -lt $SBYMIN ]; then
				elog "number of standbys must be >=$SBYMIN"
			fi
			shift;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation
validate_replication

if [ -z "$SNDDATA" ]; then
	pgbackup.sh $ACTDATA
else
	validate_cascade_replication

	SNDPORT=$(show_guc port $SNDDATA/postgresql.conf)
	if [ -z "$SNDPORT" ]; then
		SNDPORT=5432
	fi
	ACTPORT=$SNDPORT

	rm -rf $ACTBKP
	$PGBIN/pg_basebackup -D $ACTBKP -p $SNDPORT -c fast
fi

for ((SBYID=$SBYMIN; SBYID<=$SBYMAX; SBYID++)); do
	update_pgdata $SBYDATA$SBYID

	$PGBIN/pg_ctl -D $PGDATA status > /dev/null
	if [ $? -eq 0 ]; then
		continue
	fi

	SBYPORT=$(expr $ACTPORT + $SBYID)
	TRIGGER="trigger$SBYID"

	rm -f $TRIGGER
	pgrsync.sh -b $ACTBKP $PGDATA

	set_guc port $SBYPORT $PGCONF
	set_guc log_line_prefix "'$PGDATA '" $PGCONF
	set_guc hot_standby on $PGCONF

	cat << EOF > $RECOVERYCONF
standby_mode = 'on'
primary_conninfo = 'port=$ACTPORT application_name=$PGDATA'
trigger_file = '$TRIGGER'
recovery_target_timeline = 'latest'
EOF

	if [ "$ARCHIVE_MODE" = "TRUE" ]; then
		echo "restore_command = 'cp $ACTARCH/%f %p'" >> $RECOVERYCONF
	fi

	pgstart.sh -w $PGDATA

	STARTED=$(expr $STARTED + 1)
	if [ $STARTED -ge $SBYNUM ]; then
		break
	fi
done
