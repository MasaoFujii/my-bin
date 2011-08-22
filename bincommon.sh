#!/bin/sh

PROGNAME=$(basename ${0})
TMPFILE=/tmp/binscript_$(date +%Y%m%d%H%M%S).$$.tmp
CURDIR=$(pwd)
KERNEL=$(uname)

elog ()
{
	echo "$PROGNAME:  $1" 1>&2
	if [ ! -z "$2" ]; then
		echo "$2"
	fi
	exit 1
}

remove_line ()
{
	PATTERN="$1"
	TARGETFILE="$2"
	PERM=

	case "$KERNEL" in
		"Linux")
			PERM=$(stat --format "%a" $TARGETFILE);;
		"Darwin")
			PERM=$(stat -f "%p" $TARGETFILE);;
		*)
			elog "unknown kernel: $KERNEL";;
	esac
	sed /"$PATTERN"/D $TARGETFILE > $TMPFILE
	mv $TMPFILE $TARGETFILE
	chmod $PERM $TARGETFILE
}
