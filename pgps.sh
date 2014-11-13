#!/bin/sh

. pgcommon.sh

BATCH=false
DELAY=1
ONETIME=false
FORMAT="u"

usage ()
{
cat <<EOF
$PROGNAME provides a dynamic real-time view of running postgres processes.

Usage:
  $PROGNAME [OPTIONS]

Description:
  By default, screen is updated every 1 second.

Options:
  -b          batch mode; reports running processes in a row
  -d SECS     specifies the delay between screen updates or
              reports in batch mode
  -o FORMAT   uses user-defined format, e.g., -o pid
  u           uses user-oriented format (default format)
  -1          1-time mode; reports running processes only once

Notes:
  -1 is given priority over -b if both are specified.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-b)
			BATCH=true;;
		-d)
			DELAY="$2"
			shift;;
		"-?"|--help)
			usage
			exit 0;;
		-o)
			FORMAT="-o $2"
			shift;;
		u)
			FORMAT="u";;
		-1)
			ONETIME=true;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

report_pgsql_processes ()
{
	date

	for processname in postgres postmaster; do
		PIDLIST=$(pgrep -d, -x $processname)
		if [ ! -z "$PIDLIST" ]; then
			ps $FORMAT -p $PIDLIST
			echo ""
			return
		fi
	done
}

if [ "$ONETIME" = "true" ]; then
	report_pgsql_processes
	exit 0
fi

if [ "$BATCH" = "true" ]; then
	while [ 1 ]; do
		report_pgsql_processes
		sleep $DELAY
	done
else
	watch -n$DELAY "$PROGNAME -1 $FORMAT"
fi
