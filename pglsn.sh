#!/bin/sh

. pgcommon.sh

usage ()
{
cat <<EOF
$PROGNAME shows current WAL location.

Usage:
  $PROGNAME [PGDATA]
EOF
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
pgdata_exists
pgsql_is_alive

prepare_psql

cat <<EOF | $PSQL
SELECT pg_current_xlog_location();
EOF
