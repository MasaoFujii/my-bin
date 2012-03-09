#!/bin/bash

. pgcommon.sh

CONFFILE=$GUCFILENAME
SHOWGUCS=
SETGUC=
NSETGUC=0
SHOWCHANGED=false

usage ()
{
	echo "$PROGNAME opens PostgreSQL configuration file."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -p               opens $GUCFILENAME (default)"
	echo "  -h               opens $HBAFILENAME"
	echo "  -r               opens $RECFILENAME"
	echo "  -c NAME=VALUE    changes specified parameter"
	echo "                   (enclose VALUE with double quotes to include single"
	echo "                   quote in it, e.g., listen_addresses=\"'*'\")"
	echo "  -s NAME[,...]    shows values of specified parameters"
	echo "  -S               shows all changed (not default) parameters"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-p)
			CONFFILE=$GUCFILENAME;;
		-h)
			CONFFILE=$HBAFILENAME;;
		-r)
			CONFFILE=$RECFILENAME;;
		-c)
			SETGUC[$NSETGUC]="$2"
			NSETGUC=$(expr $NSETGUC + 1)
			shift;;
		-s)
			SHOWGUCS="$SHOWGUCS,$2"
			shift;;
		-S)
			SHOWCHANGED=true;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists

show_params ()
{
	for GUCNAME in $(echo "$SHOWGUCS" | sed s/','/' '/g); do
		GUCVALUE=$(show_guc "$GUCNAME" $PGCONF)
		if [ ! -z "$GUCVALUE" ]; then
			echo "$GUCNAME = $GUCVALUE"
		fi
	done
}

show_changed ()
{
	grep -E ^[A-z] $PGCONF | cut -f1
}

change_params ()
{
	for ((i=0; i<$NSETGUC; i++)); do
		GUCNAME=$(echo "${SETGUC[$i]}" | cut -d= -f1)
		GUCVALUE=$(echo "${SETGUC[$i]}" | cut -d= -f2)
		set_guc "$GUCNAME" "$GUCVALUE" $PGCONF
		SHOWGUCS="$SHOWGUCS,$GUCNAME"
	done

	show_params
}

if [ $NSETGUC -gt 0 ]; then
	change_params
	exit 0
fi

if [ ! -z "$SHOWGUCS" ]; then
	show_params
	exit 0
fi

if [ "$SHOWCHANGED" = "true" ]; then
	show_changed
	exit 0
fi

emacs $PGDATA/$CONFFILE &
