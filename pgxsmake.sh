#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgxsmake.log

PREFIX=
MAKECMD=

usage ()
{
	echo "$PROGNAME compiles and installs PostgreSQL module with PGXS."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] PREFIX"
	echo ""
	echo "Default:"
	echo "  runs just \"make\""
	echo ""
	echo "Options:"
	echo "  -c    runs \"make clean\""
	echo "  -i    runs \"make install\""
	echo "  -u    runs \"make uninstall\""
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-c)
			MAKECMD="clean";;
		-i)
			MAKECMD="install";;
		-u)
			MAKECMD="uninstall";;
		-*)
			elog "invalid option: $1";;
		*)
			PREFIX="$1";;
	esac
	shift
done

if [ ! -f $CURDIR/Makefile ]; then
	elog "here is NOT module source directory: \"$CURDIR\""
fi

if [ -z "$PREFIX" ]; then
	elog "PREFIX must be supplied"
fi

make USE_PGXS=1 PG_CONFIG=$PREFIX/bin/pg_config $MAKECMD > $LOGFILE 2>&1

cat $LOGFILE
echo -e "\n"
grep -a warning $LOGFILE
