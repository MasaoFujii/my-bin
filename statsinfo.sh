#!/bin/sh

PROGNAME=$(basename ${0})

OP=
if [ -z "$LOGDIR" ]; then
	LOGDIR=$(date +%Y%m%d%H%M%S)
fi

USE_AL=true
USE_IO=false
USE_PS=false
USE_SA=false
USE_VM=false

SECS_IO=5
SECS_PS=20
SECS_SA=5
SECS_VM=5

HAVE_ARG=false

usage ()
{
	echo "$PROGNAME collects performance information"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME start  [OPTIONS]"
	echo "  $PROGNAME stop   [OPTIONS]"
	echo "  $PROGNAME status [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -h                     shows this help, then exits"
	echo "  -i [SECS]              uses \"iostat -t -x\""
	echo "  -l LOGDIR              location of log directory"
	echo "  -p [SECS]              uses \"ps aux\""
	echo "  -s [SECS]              uses \"sar -A\""
	echo "  -v [SECS]              uses \"vmstat -n\""
}

check_segs ()
{
	SECS="$2"
	NEED_SHIFT=true
	if [ "$1" != "-$3" ]; then
		SECS=$(echo "$1" | sed s/^-$3//)
		NEED_SHIFT=false
	fi
	test "$SECS" -eq 0 > /dev/null 2>&1
	if [ $? -le 1 ]; then
		eval "$4=$SECS"
		HAVE_ARG=$NEED_SHIFT
	fi
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		-i*)
			USE_IO=true
			USE_AL=false
			check_segs "$1" "$2" i SECS_IO;;
		-l)
			LOGDIR="$2"
			shift;;
		-l*)
			LOGDIR=$(echo "$1" | sed s/^-l//);;
		-p*)
			USE_PS=true
			USE_AL=false
			check_segs "$1" "$2" p SECS_PS;;
		-s*)
			USE_SA=true
			USE_AL=false
			check_segs "$1" "$2" s SECS_SA;;
		-v*)
			USE_VM=true
			USE_AL=false
			check_segs "$1" "$2" v SECS_VM;;
		-*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
		start)
			OP=start;;
		stop)
			OP=stop;;
		status)
			OP=status;;
		*)
			echo "$PROGNAME: invalid operation mode: $1" 1>&2
			exit 1;;
	esac
	if [ "$HAVE_ARG" = "true" ]; then
		shift
		HAVE_ARG=false
	fi
	shift
done

if [ -z "$OP" ]; then
	echo "$PROGNAME: no operation mode specified" 1>&2
	exit 1
fi

LOG_SI="$LOGDIR/statsinfo.log"
LOG_IO="$LOGDIR/iostat.log"
LOG_PS="$LOGDIR/ps.log"
LOG_SA="$LOGDIR/sar.log"
LOG_VM="$LOGDIR/vmstat.log"

PID_SI=
PID_IO=
PID_PS=
PID_SA=
PID_VM=

callback ()
{
	kill -TERM $PID_IO $PID_PS $PID_SA $PID_VM
	exit 0
}
trap 'callback' INT TERM QUIT

ps_loop ()
{
	while [ 1 ]; do
		ps aux >> $LOG_PS
		sleep $SECS_PS
	done
}

PIDFILE="$LOGDIR/.statsinfo"
read_status ()
{
	if [ ! -f $PIDFILE ]; then
		echo "$PROGNAME: could not find $PIDFILE" 1>&2
		exit 1
	fi
	. $PIDFILE
}
write_status ()
{
	echo "\
PID_SI=$PID_SI
PID_IO=$PID_IO
PID_PS=$PID_PS
PID_SA=$PID_SA
PID_VM=$PID_VM
" > $PIDFILE
}

output_log ()
{
	echo $(date +"%Y/%m/%d %H:%M:%S")"    ""$1" | tee -a $LOG_SI
}
have_stats ()
{
	which $1 > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "$PROGNAME: $1 not found"
		exit 1
	fi
}
if [ "$OP" = "start" ]; then
	PID_SI=$$
	have_stats iostat
	have_stats ps
	have_stats sar
	have_stats vmstat
	if [ -d $LOGDIR ]; then
		echo "$PROGNAME: directory \"$LOGDIR\" exists but is not empty"
		exit 1
	fi
	mkdir $LOGDIR
	output_log "creating directory \"$LOGDIR\""

	if [ "$USE_IO" = "true" -o "$USE_AL" = "true" ]; then
		iostat -t -x $SECS_IO > $LOG_IO &
		PID_IO=$!
		output_log "starting iostat (PID: $PID_IO)"
	fi

	if [ "$USE_PS" = "true" -o "$USE_AL" = "true" ]; then
		ps_loop &
		PID_PS=$!
		output_log "starting ps (PID: $PID_PS)"
	fi

	if [ "$USE_SA" = "true" -o "$USE_AL" = "true" ]; then
		sar -A -o $LOG_SA $SECS_SA > /dev/null &
		PID_SA=$!
		output_log "starting sar (PID: $PID_SA)"
	fi

	if [ "$USE_VM" = "true" -o "$USE_AL" = "true" ]; then
		vmstat -n $SECS_VM > $LOG_VM &
		PID_VM=$!
		output_log "starting vmstat (PID: $PID_VM)"
	fi

	write_status
fi

kill_stats ()
{
	if [ "$1" = "true" -o "$USE_AL" = "true" ]; then
		if [ ! -z "$2" ]; then
			kill "$2"
			eval "$3="
			output_log "stopping $4 (PID: $2)"
		fi
	fi
}
if [ "$OP" = "stop" ]; then
	read_status
	kill_stats "$USE_IO" "$PID_IO" PID_IO iostat
	kill_stats "$USE_PS" "$PID_PS" PID_PS ps
	kill_stats "$USE_SA" "$PID_SA" PID_SA sar
	kill_stats "$USE_VM" "$PID_VM" PID_VM vmstat
	write_status
fi

STATUS_RET=1
show_status ()
{
	if [ "$1" = "true" -o "$USE_AL" = "true" ]; then
		if [ ! -z "$2" ]; then
			echo "$3 is running (PID: $2)"
			STATUS_RET=0
		else
			echo "no $3 is running"
		fi
	fi
}
if [ "$OP" = "status" ]; then
	read_status
	show_status "$USE_IO" "$PID_IO" iostat
	show_status "$USE_PS" "$PID_PS" ps
	show_status "$USE_SA" "$PID_SA" sar
	show_status "$USE_VM" "$PID_VM" vmstat
	exit $STATUS_RET
fi
