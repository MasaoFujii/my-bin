#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgmake.log

PREFIX=
DEBUG_MODE="FALSE"
ONLYMAKE="FALSE"

CONFOPT=
NUMJOBS=4

usage ()
{
cat <<EOF
$PROGNAME compiles and installs PostgreSQL.

Usage:
  $PROGNAME [OPTIONS] PREFIX

Options:
  -c OPTIONS    uses OPTIONS as extra configure options
  -d            compiles for debug purpose: uses --enable-debug and
                --enable-cassert, and prevents compiler optimization
  -f FLAG       uses FLAG as CPPFLAGS, e.g. -f "-DWAL_DEBUG"
  -j NUM        number of jobs (default: 4)
  -m            compiles without clean and configure
  --libxml      builds with XML support, i.e., same as -c "--with-libxml"
  --llvm        builds with LLVM based JIT support, i.e., same as -c "--with-llvm"
  --tap         enables TAP tests, i.e., same as -c "--enable-tap-tests"
  --wal-debug   same as -f "-DWAL_DEBUG"
EOF
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

	make -s -j $NUMJOBS install
	echo -e "\n"

	CONTRIB=$CURDIR/contrib
	cd $CONTRIB
	make -s -j $NUMJOBS install
	cd $CURDIR
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
			NUMJOBS=$2
			shift;;
		-m)
			ONLYMAKE=TRUE;;
		--libxml)
			CONFOPT="--with-libxml $CONFOPT";;
		--llvm)
			CONFOPT="--with-llvm $CONFOPT";;
		--tap)
			CONFOPT="--enable-tap-tests $CONFOPT";;
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
grep -a warning $LOGFILE
