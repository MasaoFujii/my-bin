#!/bin/sh

. pgcommon.sh

CONFFILE="postgresql.conf"
SHOWGUCNAMES=

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
			SHOWGUCNAMES="$SHOWGUCNAMES,$2"
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

if [ ! -z "$SHOWGUCNAMES" ]; then
	CONFFILE="postgresql.conf"
	for GUCNAME in $(echo "$SHOWGUCNAMES" | sed s/','/' '/g); do
		GUCVALUE=$(show_guc "$GUCNAME" $PGDATA/$CONFFILE)
		if [ ! -z "$GUCVALUE" ]; then
			echo "$GUCNAME = $GUCVALUE"
		fi
	done
	exit 0
fi

emacs $PGDATA/$CONFFILE &
