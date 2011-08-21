#!/bin/sh

. pgcommon.sh

CONFFILE="postgresql.conf"

usage ()
{
	echo "$PROGNAME opens PostgreSQL configuration file."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -p    postgresql.conf (default)"
	echo "  -h    pg_hba.conf"
	echo "  -r    recovery.conf"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-p)
			CONFFILE="postgresql.conf";;
		-h)
			CONFFILE="pg_hba.conf";;
		-r)
			CONFFILE="recovery.conf";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists

emacs $PGDATA/$CONFFILE &
