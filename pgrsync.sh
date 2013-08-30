#!/bin/sh

. pgcommon.sh

SRCDIR=
DSTDIR=
OPT="-a --delete"
BACKUP_MODE="FALSE"

make_path_canonical ()
{
	DIRNAME=$(dirname "$1")
	FILENAME=$(basename "$1")
	echo "$DIRNAME/$FILENAME"
}

usage ()
{
cat <<EOF
$PROGNAME is a fast PostgreSQL-related file-copying tool.

Usage:
  $PROGNAME [OPTIONS] SRCDIR DSTDIR

Description:
  This utility is a wrapper of rsync, especially customized for PostgreSQL-related files and directories.

Options:
  -b    backup mode (excludes pg_xlog and postmaster.pid and deletes extraneous files)
  -v    increases verbosity
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-b)
			OPT="$OPT --delete --exclude=pg_xlog/* --exclude=postmaster.pid"
			BACKUP_MODE="TRUE";;
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
	elog "SRCDIR and DSTDIR must be supplied"
fi

rsync $OPT $SRCDIR/ $DSTDIR

if [ "$BACKUP_MODE" = "TRUE" ]; then
	rm -rf $DSTDIR/pg_xlog/*
	mkdir $DSTDIR/pg_xlog/archive_status
fi
