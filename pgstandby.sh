#!/bin/bash

. pgcommon.sh

ACTARCH=$CURDIR/data.arch
ACTBKP=$CURDIR/data.bkp

SBYID=0
SBYNUM=1
STARTED=0

SNDDATA=
SNDPORT=5432

ARCHIVE_MODE="FALSE"

usage ()
{
cat <<EOF
$PROGNAME sets up the standby(s).

Usage:
  $PROGNAME [OPTIONS]

Options:
  -a         enables WAL archiving
  -c SENDER  sets up the cascade standby
  -n NUM     number of standbys (default: 1)
EOF
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

	rm -rf $ACTBKP
	$PGBIN/pg_basebackup -D $ACTBKP -p $SNDPORT -c fast
fi

for ((SBYID=$SBYMIN; SBYID<=$SBYMAX; SBYID++)); do
	update_pgdata $SBYDATA$SBYID

	$PGBIN/pg_ctl -D $PGDATA status > /dev/null
	if [ $? -eq 0 ]; then
		continue
	fi

	SBYPORT=$(expr 5432 + $SBYID)
	TRIGGER="trigger$SBYID"

	rm -f $TRIGGER
	pgrsync.sh -b $ACTBKP $PGDATA

	set_guc port $SBYPORT $PGCONF
	set_guc log_line_prefix "'%t $PGDATA '" $PGCONF
	set_guc hot_standby on $PGCONF

	if [ $PGMAJOR -ge 120 ]; then
		set_guc primary_conninfo "'port=$SNDPORT application_name=$PGDATA'" $PGCONF
		set_guc promote_trigger_file "'$TRIGGER'" $PGCONF
		set_guc recovery_target_timeline "'latest'" $PGCONF
		touch $STANDBYSIGNAL
	else
		cat << EOF > $RECOVERYCONF
standby_mode = 'on'
primary_conninfo = 'port=$SNDPORT application_name=$PGDATA'
trigger_file = '$TRIGGER'
recovery_target_timeline = 'latest'
EOF
	fi

	if [ "$ARCHIVE_MODE" = "TRUE" ]; then
		if [ $PGMAJOR -ge 120 ]; then
			set_guc restore_command "'cp $ACTARCH/%f %p'" $PGCONF
		else
			echo "restore_command = 'cp $ACTARCH/%f %p'" >> $RECOVERYCONF
		fi
	fi

	pgstart.sh -w $PGDATA

	STARTED=$(expr $STARTED + 1)
	if [ $STARTED -ge $SBYNUM ]; then
		break
	fi
done
