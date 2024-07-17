#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgmake.log

PREFIX=
DEBUG_MODE="FALSE"
ONLYMAKE="FALSE"
USE_LZ4="TRUE"
USE_ICU="FALSE"

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
  --icu         builds with support for ICU library (by default ICU collation is disabled)"
  --tap         enables TAP tests, i.e., same as -c "--enable-tap-tests"
  --no-lz4      do not use --with-lz4 (by default use --with-lz4 in v14 or later)"
  --wal-debug   same as -f "-DWAL_DEBUG"
EOF
}

compile_pgsql ()
{
	export LANG=C

	if [ "$ONLYMAKE" = "FALSE" ]; then
		pgclean.sh -m

		./configure --prefix=$PREFIX $CONFOPT
	fi

	make -s -j $NUMJOBS install
	echo -e "\n"

	CONTRIB=$CURDIR/contrib
	cd $CONTRIB
	make -s -j $NUMJOBS install
	cd $CURDIR

	if [ $PGMAJOR -ge 160 ]; then
		PGBSDINDENT=$CURDIR/src/tools/pg_bsd_indent
		cd $PGBSDINDENT
		make -s -j $NUMJOBS
		cd $CURDIR
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
			CONFOPT="--enable-debug --enable-cassert CFLAGS=-O0 $CONFOPT"
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
		--icu)
			USE_ICU=TRUE;;
		--tap)
			CONFOPT="--enable-tap-tests $CONFOPT";;
		--no-lz4)
			USE_LZ4=FALSE;;
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

if [ "$USE_LZ4" = "TRUE" -a $PGMAJOR -ge 140 ]; then
	CONFOPT="--with-lz4 $CONFOPT"
fi

if [ "$USE_ICU" = "TRUE" -a $PGMAJOR -le 150 ]; then
	CONFOPT="--with-icu $CONFOPT"
elif [ "$USE_ICU" = "FALSE" -a $PGMAJOR -ge 160 ]; then
	CONFOPT="--without-icu $CONFOPT"
fi

compile_pgsql > $LOGFILE 2>&1

cat $LOGFILE
echo -e "\n"
grep -a warning $LOGFILE
