#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgmake.log

PREFIX=
DEBUG_MODE="FALSE"
ONLYMAKE="FALSE"

CONFOPT=
MAKEOPT=

usage ()
{
	echo "$PROGNAME compiles and installs PostgreSQL."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] PREFIX"
	echo ""
	echo "Options:"
	echo "  -c OPTIONS    uses OPTIONS as extra configure options"
	echo "  -d            compiles for debug purpose: uses --enable-debug and"
	echo "                --enable-cassert, and prevents compiler optimization"
	echo "  -f FLAG       uses FLAG as CPPFLAGS, e.g. -f \"-DWAL_DEBUG\""
	echo "  -j NUM        number of jobs"
	echo "  -m            compiles without clean and configure"
	echo "  --wal-debug   same as -f \"-DWAL_DEBUG\""
}

compile_pgsql ()
{
	export LANG=C

	if [ "$ONLYMAKE" = "FALSE" ]; then
		pgclean.sh -m

		./configure --prefix=$PREFIX $CONFOPT
		if [ "$DEBUG_MODE" = "TRUE" ]; then
			MAKEFILE=$CURDIR/src/Makefile.global
			sed s/"\-O2"/"\-O0"/g $MAKEFILE > $TMPFILE
			mv $TMPFILE $MAKEFILE
		fi
	fi

	make $MAKEOPT
	make install
	echo -e "\n"

	CONTRIB=$CURDIR/contrib
	PGBENCH=$CONTRIB/pgbench
	if [ -d $PGBENCH ]; then
		cd $PGBENCH
		make install
	fi
	PGSBY=$CONTRIB/pg_standby
	if [ -d $PGSBY ]; then
		cd $PGSBY
		make install
	fi
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-c)
			CONFOPT="$2 $CONFOPT"
			shift;;
		-d)
			CONFOPT="--enable-debug --enable-cassert $CONFOPT"
			DEBUG_MODE="TRUE";;
		-f|--flag)
			export CPPFLAGS="$2 $CPPFLAGS"
			shift;;
		-j)
			MAKEOPT="-j $2"
			shift;;
		-m)
			ONLYMAKE=TRUE;;
		--wal-debug)
			export CPPFLAGS="-DWAL_DEBUG $CPPFLAGS";;
		-*)
			elog "invalid option: $1";;
		*)
			PREFIX="$1";;
	esac
	shift
done

here_is_source

if [ -z "$PREFIX" -a "$ONLYMAKE" = "FALSE" ]; then
	elog "PREFIX must be supplied"
fi

compile_pgsql > $LOGFILE 2>&1

cat $LOGFILE
echo -e "\n"
grep warning $LOGFILE
