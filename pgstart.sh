#!/bin/sh

. pgcommon.sh

OPT=
RENAMECONF="FALSE"

usage ()
{
	echo "$PROGNAME starts PostgreSQL server."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -r    renames recovery.done to .conf before the start"
	echo "  -w    waits for the start to complete"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-r)
			RENAMECONF="TRUE";;
		-w)
			OPT="-w";;
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

$PGBIN/pg_ctl $OPT -D $PGDATA start
