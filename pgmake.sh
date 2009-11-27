#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgmake.log
PREFIX=
OPERATION=

Usage ()
{
    echo "${PROGNAME} compiles and installs pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [-f FLAG] PREFIX [debug]"
    echo ""
    echo "Options:"
    echo "  -f FLAG      uses FLAG as CPPFLAGS"
}

CompilePgsql ()
{
	export LANG=C
	pgclean.sh -m

	case ${OPERATION} in
		"debug")
			CONFIGOPTS="--enable-debug --enable-cassert"
			./configure --prefix=${PREFIX} ${CONFIGOPTS}
			MAKEFILE=${CURDIR}/src/Makefile.global
			sed s/\-O2//g ${MAKEFILE} > ${TMPFILE}
			mv ${TMPFILE} ${MAKEFILE};;
		*)
			CONFIGOPTS="--enable-debug"
			./configure --prefix=${PREFIX} ${CONFIGOPTS};;
	esac

	make install
	echo -e "\n"

    cd ${CURDIR}/contrib/pgbench
    make install
    cd ${CURDIR}/contrib/pg_standby
    make install
}

CurDirIsPgsqlSrc
while getopts "f:h" OPT; do
	case ${OPT} in
		f)
			export CPPFLAGS="${OPTARG} ${CPPFLAGS}";;
		h)
			Usage
			exit 0;;
		*)
			exit 1;;
	esac
done
shift $(expr ${OPTIND} - 1)

if [ ${#} -lt 1 ]; then
	echo "ERROR: PREFIX must be supplied"
	exit 1
fi
PREFIX="${1}"
OPERATION="${2}"

CompilePgsql > ${LOGFILE} 2>&1
