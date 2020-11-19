#!/bin/sh

PROGNAME=$(basename ${0})
CURTIME=$(date +%Y%m%d%H%M%S)
TMPFILE=/tmp/binscript_${CURTIME}.$$.tmp
CURDIR=$(pwd)
KERNEL=$(uname)

PROGPATH=$(which ${0})
PROGDIR=$(dirname ${PROGPATH})
PROGDATA=${PROGDIR}/data

elog ()
{
	echo "$PROGNAME:  $1" 1>&2
	if [ ! -z "$2" ]; then
		echo "$2"
	fi
	exit 1
}

exit_on_error ()
{
	if [ $? -ne 0 ]; then
		if [ ! -z "$1" ]; then
			exit $1
		else
			exit 1
		fi
	fi
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
	esac
	sed /"$PATTERN"/D $TARGETFILE > $TMPFILE
	mv $TMPFILE $TARGETFILE
	chmod $PERM $TARGETFILE
}

if [ "$KERNEL" != "Linux" -a "$KERNEL" != "Darwin" ]; then
			elog "unknown kernel: $KERNEL"
fi
