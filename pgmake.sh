#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgmake.log

PREFIX=
DEBUG_MODE="FALSE"
PGMAKE_MODE="NORMAL"
USE_LZ4="TRUE"
USE_ICU="FALSE"

CONFOPT=
NUMJOBS=4
CFLAGS="-pipe"

usage ()
{
cat <<EOF
$PROGNAME compiles and installs PostgreSQL.

Usage:
  $PROGNAME [OPTIONS] PREFIX

Options:
  -c OPTIONS    uses OPTIONS as extra configure options
  -d            compiles for debug purpose: uses --enable-debug,
                --enable-cassert, --enable-injection-points (>= v17),
                --enable-tap-tests (>= v9.4),
                and prevents compiler optimization
  -f FLAG       uses FLAG as CPPFLAGS, e.g. -f "-DWAL_DEBUG"
  -j NUM        number of jobs (default: 4)
  -m            compiles without clean and configure
  --configure   runs only clean and configure
  --libxml      builds with XML support, i.e., same as -c "--with-libxml"
  --llvm        builds with LLVM based JIT support, i.e., same as -c "--with-llvm"
  --icu         builds with support for ICU library (by default ICU collation is disabled)"
  --no-lz4      do not use --with-lz4 (by default use --with-lz4 in v14 or later)"
  --wal-debug   same as -f "-DWAL_DEBUG"
EOF
}

compile_pgsql ()
{
	export LANG=C

	if [ "$PGMAKE_MODE" != "ONLYMAKE" ]; then
		pgclean.sh -m
		./configure --prefix=$PREFIX $CONFOPT CFLAGS="$CFLAGS"
	fi

	if [ "$PGMAKE_MODE" = "ONLYCONFIGURE" ]; then
		return;
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
			DEBUG_MODE=TRUE;;
		-f|--flag)
			export CPPFLAGS="$2 $CPPFLAGS"
			shift;;
		-j)
			NUMJOBS=$2
			shift;;
		-m)
			PGMAKE_MODE="ONLYMAKE";;
		--configure)
			PGMAKE_MODE="ONLYCONFIGURE";;
		--libxml)
			CONFOPT="--with-libxml $CONFOPT";;
		--llvm)
			CONFOPT="--with-llvm $CONFOPT";;
		--icu)
			USE_ICU=TRUE;;
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

if [ "$DEBUG_MODE" = "TRUE" ]; then
	CONFOPT="--enable-debug --enable-cassert $CONFOPT"
	if [ $PGMAJOR -ge 170 ]; then
		CONFOPT="--enable-injection-points $CONFOPT"
	fi
	if [ $PGMAJOR -ge 94 ]; then
		CONFOPT="--enable-tap-tests $CONFOPT"
	fi
	CFLAGS="-O0 $CFLAGS"
fi

if [ -z "$PREFIX" -a "$PGMAKE_MODE" != "ONLYMAKE" ]; then
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
