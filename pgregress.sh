#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgregress.log
TESTCMD=check-world
NUMJOBS=4

usage ()
{
cat <<EOF
$PROGNAME performs make $TESTCMD.

Usage:
  $PROGNAME [OPTIONS]

Options:
  -j NUM    number of jobs (default: 4)
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-j)
			NUMJOBS=$2
			shift;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_source

do_make_check ()
{
	time make -s -j $NUMJOBS $TESTCMD
	if [ $? -eq 0 ]; then
		echo "SUCCESS"
	else
		echo "FAILURE"
	fi
}

do_make_check > $LOGFILE 2>&1
tail -1 $LOGFILE
