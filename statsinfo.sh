#!/bin/sh

PROGNAME=$(basename ${0})

OP=
LOGDIR=$(date +%Y%m%d%H%M%S)

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
	if [ "$HAVE_ARG" == "true" ]; then
		shift
	fi
	shift
done

if [ -z "$OP" ]; then
	echo "$PROGNAME: no operation mode specified" 1>&2
	exit 1
fi

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

if [ "$OP" = "start" ]; then
	PID_SI=$$
	mkdir $LOGDIR

	if [ "$USE_IO" = "true" -o "$USE_AL" = "true" ]; then
		iostat -t -x $SECS_IO > $LOG_IO &
		PID_IO=$!
	fi

	if [ "$USE_PS" = "true" -o "$USE_AL" = "true" ]; then
		ps_loop &
		PID_PS=$!
	fi

	if [ "$USE_SA" = "true" -o "$USE_AL" = "true" ]; then
		sar -A -o $LOG_SA $SECS_SA 0 > /dev/null &
		PID_SA=$!
	fi

	if [ "$USE_VM" = "true" -o "$USE_AL" = "true" ]; then
		vmstat -n $SECS_VM > $LOG_VM &
		PID_VM=$!
	fi

	write_status
fi

kill_stats ()
{
	if [ "$1" = "true" -o "$USE_AL" = "true" ]; then
		if [ ! -z "$2" ]; then
			kill "$2"
			eval "$3="
		fi
	fi
}
if [ "$OP" = "stop" ]; then
	read_status
	kill_stats "$USE_IO" "$PID_IO" PID_IO
	kill_stats "$USE_PS" "$PID_PS" PID_PS
	kill_stats "$USE_SA" "$PID_SA" PID_SA
	kill_stats "$USE_VM" "$PID_VM" PID_VM
	write_status
fi

STATUS_RET=1
show_status ()
{
	if [ "$1" = "true" -o "$USE_AL" = "true" ]; then
		if [ ! -z "$2" ]; then
			echo "$PROGNAME: $3 is running (PID: $2)"
			STATUS_RET=0
		else
			echo "$PROGNAME: no $3 is running"
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