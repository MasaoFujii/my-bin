#!/bin/sh

. pgcommon.sh

OPT=
INITDB_OPT=
RENAMECONF="FALSE"
MAXWAIT=3600

usage ()
{
cat <<EOF
$PROGNAME starts PostgreSQL server.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -a         enables WAL archiving if initializing PGDATA
  -k         uses data page checksums if initializing PGDATA
  -r         renames recovery.done to .conf before the start
  -t SECS    seconds to wait when using -w option (default: 3600s)
  -T         uses auto tuning
  -w         waits for the start to complete
  -X         uses external XLOG directory if initializing PGDATA
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			INITDB_OPT="-a $INITDB_OPT";;
		-k)
			INITDB_OPT="-k $INITDB_OPT";;
		-r)
			RENAMECONF="TRUE";;
		-t)
			MAXWAIT=$2
			shift;;
		-T)
			INITDB_OPT="-T $INITDB_OPT";;
		-w)
			OPT="-w $OPT";;
		-X)
			INITDB_OPT="-X $INITDB_OPT";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

if [ ! -d $PGDATA ]; then
	pginitdb.sh $INITDB_OPT $PGDATA
	exit_on_error
fi

pgsql_is_dead

if [ $PGMAJOR -ge 83 ]; then
	OPT="-c $OPT"
fi

if [ "$RENAMECONF" = "TRUE" -a -f $RECOVERYDONE ]; then
	mv $RECOVERYDONE $RECOVERYCONF
fi

$PGBIN/pg_ctl $OPT -D $PGDATA -t $MAXWAIT start
