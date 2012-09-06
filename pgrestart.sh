#!/bin/sh

. pgcommon.sh

STOPOPT=
STARTOPT=

usage ()
{
	echo "$PROGNAME restarts PostgreSQL server."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -s    smart shutdown"
	echo "  -f    fast shutdown (default)"
	echo "  -i    immediate shutdown"
	echo "  -w    waits for the start to complete"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-s)
			STOPOPT="-s";;
		-f)
			STOPOPT="-f";;
		-i)
			STOPOPT="-i";;
		-w)
			STARTOPT="-w";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists
pgsql_is_alive

pgshutdown.sh $STOPOPT $PGDATA
pgstart.sh $STARTOPT $PGDATA
