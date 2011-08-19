#!/bin/sh

. pgcommon

PREFIX=/dav/head-pgsql

usage ()
{
	echo "$PROGNAME downloads and compiles the HEAD"
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

if [ ! -d $CURDIR/.git ]; then
	elog "here \"$CURDIR\" is not git directory"
fi

pgclean.sh -a
git pull
pgetags.sh
rm -rf $PREFIX
pgmake.sh -d $PREFIX
