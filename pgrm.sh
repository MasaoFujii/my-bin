#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME removes pgsql directories"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME"
	echo ""
	echo "Description:"
	echo "  All unused database cluster, archive and backup directories"
	echo "  are removed from current directory."
}

here_is_installation

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
	esac
	shift
done

pgdata_children="base global pg_clog pg_xlog"

removal_pgdata ()
{
	pgdata="$1"

	if [ ! -d "$pgdata" ]; then
		return 1
	fi

	for child in $pgdata_children; do
		if [ ! -d "$pgdata/$child" ]; then
			return 1
		fi
	done

	$PGBIN/pg_ctl -D "$pgdata" status > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		return 1
	fi

	return 0
}

for pgdata in $(ls $CURDIR); do
	removal_pgdata "$pgdata"
	if [ $? -eq 0 ]; then
		echo "rm -rf $pgdata"
		rm -rf "$pgdata"
		echo "rm -rf $pgdata.arh"
		rm -rf "$pgdata.arh"
		echo "rm -rf $pgdata.bkp"
		rm -rf "$pgdata.bkp"
		echo "rm -rf $pgdata.arh.bkp"
		rm -rf "$pgdata.arh.bkp"
	fi
done
