#!/bin/sh

. pgcommon.sh

CONFFILE="postgresql.conf"
SHOWGUCS=

usage ()
{
	echo "$PROGNAME opens PostgreSQL configuration file."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -p               opens postgresql.conf (default)"
	echo "  -h               opens pg_hba.conf"
	echo "  -r               opens recovery.conf"
	echo "  -s NAME[,...]    shows values of specified parameters"
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
		-s)
			SHOWGUCS="$2 $SHOWGUCS"
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

if [ ! -z "$SHOWGUCS" ]; then
	CONFFILE="postgresql.conf"
	for gucname in $(echo "$SHOWGUCS" | sed s/','/' '/g); do
		show_guc "$gucname" $PGDATA/$CONFFILE
	done
	exit 0
fi

emacs $PGDATA/$CONFFILE &
