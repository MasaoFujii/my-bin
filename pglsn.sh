#!/bin/sh

. bincommon.sh

LSN=

usage ()
{
    echo "$PROGNAME converts a lsn to a byte offset"
    echo ""
    echo "Usage:"
    echo "  $PROGNAME LSN"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			if [ -z "$LSN" ]; then
				LSN="$1"
			else
				elog "too many arguments"
			fi;;
	esac
	shift
done

if [ -z "$LSN" ]; then
	elog "LSN must be supplied"
fi

XLOGID=$(echo $LSN | cut -d/ -f1)
XRECOFF=$(echo $LSN | cut -d/ -f2)

XLOGFILESIZE=FFFFFFFF

echo "ibase=16; $XLOGID * $XLOGFILESIZE + $XRECOFF" | bc
