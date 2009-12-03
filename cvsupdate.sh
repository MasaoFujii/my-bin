#!/bin/sh

. pgcommon.sh

PREFIX=/dav/head-pgsql

usage ()
{
	echo "$PROGNAME downloads and compiles the CVS HEAD"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [PREFIX]"
	echo ""
	echo "The default PREFIX is \"$PREFIX\"."
}

CurDirIsPgsqlSrc

if [ ! -d $CURDIR/CVS ]; then
	echo "$PROGNAME: here \"$CURDIR\" is not CVS directory"
	exit 1
fi

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

pgclean.sh -a
cvs update
pgetags.sh
rm -rf $PREFIX
pgmake.sh -d $PREFIX
