#!/bin/sh

. pgcommon.sh

SRCDIR=
DSTDIR=
OPT="-a"

make_path_canonical ()
{
	DIRNAME=$(dirname "$1")
	FILENAME=$(basename "$1")
	echo "$DIRNAME/$FILENAME"
}

usage ()
{
    echo "$PROGNAME is a fast PostgreSQL-related file-copying tool."
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [OPTIONS] SRCDIR DSTDIR"
    echo ""
		echo "Description:"
		echo "  This utility is a wrapper of rsync, especially customized for PostgreSQL-related files and directories."
		echo ""
		echo "Options:"
		echo "  -b    backup mode (excludes pg_xlog and postmaster.pid and deletes extraneous files)"
		echo "  -v    increases verbosity"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-b)
			OPT="$OPT --delete --exclude=pg_xlog/* --exclude=postmaster.pid";;
		-v)
			OPT="$OPT -v";;
		-*)
			elog "invalid option: $1";;
		*)
			if [ -z "$SRCDIR" ]; then
				SRCDIR=$(make_path_canonical "$1")
			elif [ -z "$DSTDIR" ]; then
				DSTDIR=$(make_path_canonical "$1")
			else
				elog "too many arguments"
			fi
			;;
	esac
	shift
done

if [ -z "$SRCDIR" -o -z "$DSTDIR" ]; then
	elog "SRCDIR and DSTDIR must be required"
fi

rsync $OPT $SRCDIR/ $DSTDIR
