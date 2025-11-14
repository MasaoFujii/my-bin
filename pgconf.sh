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
  -c NAME=VALUE    change parameter
                   (enclose VALUE with double quotes to include single
                   quote in it, e.g., listen_addresses="'*'")
  -c NAME VALUE    same as above
  -d NAME          default parameter
  -s NAME          show parameter
  -S               show all changed parameters
  --showall        show all possible parameters
  -T               auto tuning
  --pgss           set up pg_stat_statements

Notes:
  If "all" is specified in PGDATA, configuration file in all database clusters
  found are manipulated.
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
		-c)
			CONFCMD=change
			CONFARG="$2"
			echo "$CONFARG" | grep --quiet "="
			if [ $? -ne 0 ]; then
				shift
				CONFARG="${CONFARG}=${2}"
			fi
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
			CONFCMD=showchanged;;
		--showall)
			CONFCMD=showall;;
		-T)
			CONFCMD=tune;;
		--pgss)
			CONFCMD=pgss;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

report_guc ()
{
	GUCNAME="$1"
	GUCVALUE=$(show_guc "$GUCNAME" $PGCONF)
	if [ ! -z "$GUCVALUE" ]; then
		echo "$GUCNAME = $GUCVALUE"
	fi
}

MEM_KB=0
MEM_MB=0
tune_mem ()
{
	GUCNAME="$1"
	TUNENUM="$2"
	set_guc "$GUCNAME" "$(echo "$MEM_MB / $TUNENUM" | bc)MB" $PGCONF
	report_guc "$GUCNAME"
}

exec_pgconf ()
{
	pgdata_exists

	case "$CONFCMD" in
		open)
			case "$KERNEL" in
				"Linux")
					emacs $PGDATA/$CONFFILE &;;
				"Darwin")
					emacs $PGDATA/$CONFFILE;;
			esac;;

		tune)
			case "$KERNEL" in
				"Linux")
					MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}');;
				"Darwin")
					MEM_BYTES=$(sysctl hw.memsize | awk '{print $2}')
					MEM_KB=$(echo "$MEM_BYTES / 1024" | bc);;
			esac
			MEM_MB=$(echo "$MEM_KB / 1024" | bc)
			tune_mem shared_buffers       10
			tune_mem effective_cache_size 2
			tune_mem work_mem             1000
			tune_mem maintenance_work_mem 40;;

		change)
			GUCNAME=$(echo "$CONFARG" | cut -d= -f1)
			GUCVALUE=$(echo "$CONFARG" | cut -d= -f2-)
			set_guc "$GUCNAME" "$GUCVALUE" $PGCONF
			report_guc "$GUCNAME";;

		default)
			remove_line "^$CONFARG" $PGCONF;;

		show)
			report_guc "$CONFARG";;

		showchanged)
			grep -E ^[A-z] $PGCONF | cut -f1;;

		showall)
			grep -E ^[A-z]\|\#[A-z] $PGCONF | tr -d \# | cut -d= -f1 | sort | uniq;;

		pgss)
			set_guc shared_preload_libraries "'pg_stat_statements'" $PGCONF
			echo "pg_stat_statements.track = all" >> $PGCONF
			echo "pg_stat_statements.track_utility = on" >> $PGCONF
			echo "pg_stat_statements.track_planning = on" >> $PGCONF
	esac
}

if [ "$PGDATA" = "all" ]; then
	for pgdata in $(find_all_pgdata); do
		update_pgdata "$pgdata"
		exec_pgconf
	done
else
	exec_pgconf
fi
