#!/bin/sh

. pgcommon.sh

SECS=
OPTS=
LISTARCHSTATUS=false

usage ()
{
    echo "$PROGNAME lists files in pg_xlog directory"
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [OPTIONS] [PGDATA]"
    echo ""
    echo "Description:"
    echo "  By default, WAL files in pg_xlog are listed once"
    echo ""
    echo "Options:"
		echo "  -a        lists archive status files"
    echo "  -n SECS   interval; lists every SECS"
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
		ls $PGARCHSTATUS
	else
		ls $PGXLOG
	fi
else
	watch -n$SECS "pgxlog.sh $OPTS $PGDATA"
fi
