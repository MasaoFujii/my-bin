#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME creates \"etags\" files"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME"
}

check_here_is_source

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
	esac
	shift
done

$CURDIR/src/tools/make_etags
