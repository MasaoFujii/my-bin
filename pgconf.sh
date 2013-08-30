#!/bin/bash

. pgcommon.sh

CONFFILE=$GUCFILENAME
SHOWGUCS=
SETGUC=
DEFAULTGUCS=
NSETGUC=0
SHOWCHANGED=false
AUTOTUNE=false
OPENCONF=true

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
  -a               auto tuning mode
  -c NAME=VALUE    change parameter
                   (enclose VALUE with double quotes to include single
                   quote in it, e.g., listen_addresses="'*'")
  -d NAME[,...]    default parameters
  -s NAME[,...]    show parameters
  -S               show all changed parameters
EOF
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
		-a)
			AUTOTUNE=true;;
		-c)
			SETGUC[$NSETGUC]="$2"
			NSETGUC=$(expr $NSETGUC + 1)
			shift;;
		-d)
			DEFAULTGUCS="$DEFAULTGUCS,$2"
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

remove_params ()
{
	for GUCNAME in $(echo "$DEFAULTGUCS" | sed s/','/' '/g); do
		remove_line "^$GUCNAME" $PGCONF
	done
}

autotune_params ()
{
	MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	MEM_MB=$(echo "$MEM_KB / 1024" | bc)

	set_guc shared_buffers       "$(echo "$MEM_MB / 10"   | bc)MB" $PGCONF
	set_guc effective_cache_size "$(echo "$MEM_MB / 50"   | bc)MB" $PGCONF
	set_guc work_mem             "$(echo "$MEM_MB / 1000" | bc)MB" $PGCONF
	set_guc maintenance_work_mem "$(echo "$MEM_MB / 40"   | bc)MB" $PGCONF
}

if [ ! -z "$DEFAULTGUCS" ]; then
	remove_params
	OPENCONF=false
fi

if [ "$AUTOTUNE" = "true" ]; then
	autotune_params
	OPENCONF=false
fi

if [ $NSETGUC -gt 0 ]; then
	change_params
	OPENCONF=false
fi

if [ ! -z "$SHOWGUCS" ]; then
	show_params
	OPENCONF=false
fi

if [ "$SHOWCHANGED" = "true" ]; then
	show_changed
	OPENCONF=false
fi

if [ "$OPENCONF" = "true" ]; then
	emacs $PGDATA/$CONFFILE &
fi
