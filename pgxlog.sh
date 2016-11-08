#!/bin/sh

. pgcommon.sh

SECS=
OPTS=
LISTARCHSTATUS=false

usage ()
{
cat <<EOF
$PROGNAME lists files in pg_xlog/pg_wal directory

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Description:
  By default, WAL files in pg_xlog/pg_wal are listed once

Options:
  -a        lists archive status files
  -n SECS   interval; lists every SECS
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
	    usage
	    exit 0;;
		-a)
			OPTS="$OPTS -a"
			LISTARCHSTATUS=true;;
		-n)
	    SECS=$2
			shift;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists

if [ -z "$SECS" ]; then
	if [ "$LISTARCHSTATUS" = "true" ]; then
		ls -x $PGARCHSTATUS
	else
		ls -x $PGXLOG
	fi
else
	watch -n$SECS "pgxlog.sh $OPTS $PGDATA"
fi
