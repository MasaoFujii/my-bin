#!/bin/sh

. pgcommon.sh

PREFIX=/dav/head-pgsql

usage ()
{
cat <<EOF
$PROGNAME updates source from HEAD and compiles it.

Usage:
  $PROGNAME
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
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
pgmake.sh -d -j 2 $PREFIX
