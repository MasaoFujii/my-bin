#!/bin/sh

. pgcommon.sh

MYTBL=t

usage ()
{
cat <<EOF
$PROGNAME creates a simple table.

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
DROP TABLE ${MYTBL} ;
CREATE TABLE ${MYTBL} AS SELECT x i, x * 10 + x j FROM generate_series(1, 10) x ;
SELECT * FROM ${MYTBL} ;
EOF
