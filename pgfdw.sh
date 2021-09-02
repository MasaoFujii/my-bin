#!/bin/sh

. pgcommon.sh

usage ()
{
	cat <<EOF
$PROGNAME creates simple foreign table.

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

pgtbl.sh $PGDATA

prepare_psql

cat <<EOF | $PSQL
CREATE EXTENSION postgres_fdw;
CREATE SERVER loopback FOREIGN DATA WRAPPER postgres_fdw;
CREATE USER MAPPING FOR public SERVER loopback;
CREATE FOREIGN TABLE ft (i INT, j INT) SERVER loopback OPTIONS (table_name 't');
EOF
