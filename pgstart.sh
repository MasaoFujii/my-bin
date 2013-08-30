#!/bin/sh

. pgcommon.sh

OPT=
RENAMECONF="FALSE"
MAXWAIT=3600

usage ()
{
cat <<EOF
$PROGNAME starts PostgreSQL server.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -r         renames recovery.done to .conf before the start
  -t SECS    seconds to wait when using -w option (default: 3600s)
  -w         waits for the start to complete
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-r)
			RENAMECONF="TRUE";;
		-t)
			MAXWAIT=$2
			shift;;
		-w)
			OPT="-w $OPT";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

if [ ! -d $PGDATA ]; then
	pginitdb.sh $PGDATA
fi

pgsql_is_dead

if [ $PGMAJOR -ge 83 ]; then
	OPT="-c $OPT"
fi

if [ "$RENAMECONF" = "TRUE" -a -f $RECOVERYDONE ]; then
	mv $RECOVERYDONE $RECOVERYCONF
fi

$PGBIN/pg_ctl $OPT -D $PGDATA -t $MAXWAIT start
