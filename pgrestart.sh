#!/bin/sh

. pgcommon.sh

STOPOPT=
STARTOPT=

usage ()
{
cat <<EOF
$PROGNAME restarts PostgreSQL server.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -s    smart shutdown
  -f    fast shutdown (default)
  -i    immediate shutdown
  -w    waits for the start to complete
EOF
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

if [ -d $PGDATA ]; then
	$PGBIN/pg_ctl -D $PGDATA status > /dev/null
	if [ $? -eq 0 ]; then
		pgshutdown.sh $STOPOPT $PGDATA
	fi
fi
pgstart.sh $STARTOPT $PGDATA
