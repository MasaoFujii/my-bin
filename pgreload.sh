#!/bin/sh

. pgcommon.sh

usage ()
{
cat <<EOF
$PROGNAME reloads PostgreSQL configuration file.

Usage:
  $PROGNAME [PGDATA]

Notes:
  If "all" is specified in PGDATA, configuration file in all database clusters
  found are reloaded.
EOF
}

reload_config ()
{
	pgdata_exists
	pgsql_is_alive

	$PGBIN/pg_ctl -D $PGDATA reload
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

if [ "$PGDATA" = "all" ]; then
	for pgdata in $(find_all_pgdata); do
		update_pgdata "$pgdata"
		reload_config
	done
else
	reload_config
fi
