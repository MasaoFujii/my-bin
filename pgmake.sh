#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgmake.log
PREFIX=
DEBUG=false

usage ()
{
    echo "$PROGNAME compiles and installs pgsql"
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [OPTIONS] PREFIX"
		echo ""
		echo "Description:"
		echo "  PREFIX indicates an installation directory, which must be supplied."
		echo "  By default, 'configure --enable-debug' and 'make install' are run."
		echo "  The log messages of the compilation are output in $LOGFILE."
    echo ""
    echo "Options:"
		echo "  -d, --debug      compiles pgsql for debug; uses --enable-cassert"
		echo "                   option and prevents the compiler's optimization"
    echo "  -f, --flag FLAG  uses FLAG as CPPFLAGS"
}

compile_pgsql ()
{
	export LANG=C
	pgclean.sh -m

	if [ "$DEBUG" = "true" ]; then
		./configure --prefix=$PREFIX --enable-debug --enable-cassert
		MAKEFILE=$CURDIR/src/Makefile.global
		sed s/\-O2//g $MAKEFILE > $TMPFILE
		mv $TMPFILE $MAKEFILE
	else
		./configure --prefix=$PREFIX --enable-debug
	fi

	make install
	echo -e "\n"

	cd $CURDIR/contrib/pgbench
	make install
	cd $CURDIR/contrib/pg_standby
	make install
}

CurDirIsPgsqlSrc

while [ $# -gt 0 ]; do
	case "$1" in
		-d|--debug)
			DEBUG=true;;
		-f|--flag)
			export CPPFLAGS="$2 $CPPFLAGS"
			shift;;
		-h|--help|"-\?")
			usage
			exit 0;;
		-*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
		*)
			PREFIX="$2"
			shift;;
	esac
	shift
done

if [ -z "$PREFIX" ]; then
	echo "$PROGNAME: PREFIX must be supplied"
	exit 1
fi

compile_pgsql > $LOGFILE 2>&1
