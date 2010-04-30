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

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_source

if [ ! -d $CURDIR/CVS ]; then
	elog "here \"$CURDIR\" is not CVS directory"
fi

pgclean.sh -a
cvs update
pgetags.sh
rm -rf $PREFIX
pgmake.sh -d $PREFIX
