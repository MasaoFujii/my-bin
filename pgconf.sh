#!/bin/bash

. pgcommon.sh

CONFFILE=$GUCFILENAME
CONFCMD=open
CONFARG=

usage ()
{
cat <<EOF
$PROGNAME manipulates PostgreSQL configuration file.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -p               open $GUCFILENAME (default)
  -h               open $HBAFILENAME
  -r               open $RECFILENAME
  -a               auto tuning
  -c NAME=VALUE    change parameter
                   (enclose VALUE with double quotes to include single
                   quote in it, e.g., listen_addresses="'*'")
  -d NAME          default parameter
  -s NAME          show parameter
  -S               show all changed parameters
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-p)
			CONFCMD=open
			CONFFILE=$GUCFILENAME;;
		-h)
			CONFCMD=open
			CONFFILE=$HBAFILENAME;;
		-r)
			CONFCMD=open
			CONFFILE=$RECFILENAME;;
		-a)
			CONFCMD=tune;;
		-c)
			CONFCMD=change
			CONFARG="$2"
			shift;;
		-d)
			CONFCMD=default
			CONFARG="$2"
			shift;;
		-s)
			CONFCMD=show
			CONFARG="$2"
			shift;;
		-S)
			CONFCMD=showall;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists

report_guc ()
{
	GUCNAME="$1"
	GUCVALUE=$(show_guc "$GUCNAME" $PGCONF)
	if [ ! -z "$GUCVALUE" ]; then
		echo "$GUCNAME = $GUCVALUE"
	fi
}

case "$CONFCMD" in
	open)
		emacs $PGDATA/$CONFFILE &;;

	tune)
		MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
		MEM_MB=$(echo "$MEM_KB / 1024" | bc)
		set_guc shared_buffers       "$(echo "$MEM_MB / 10"   | bc)MB" $PGCONF
		set_guc effective_cache_size "$(echo "$MEM_MB / 50"   | bc)MB" $PGCONF
		set_guc work_mem             "$(echo "$MEM_MB / 1000" | bc)MB" $PGCONF
		set_guc maintenance_work_mem "$(echo "$MEM_MB / 40"   | bc)MB" $PGCONF;;

	change)
		GUCNAME=$(echo "$CONFARG" | cut -d= -f1)
		GUCVALUE=$(echo "$CONFARG" | cut -d= -f2)
		set_guc "$GUCNAME" "$GUCVALUE" $PGCONF
		report_guc "$GUCNAME";;

	default)
		remove_line "^$CONFARG" $PGCONF;;

	show)
		report_guc "$CONFARG";;

	showall)
		grep -E ^[A-z] $PGCONF | cut -f1;;
esac
