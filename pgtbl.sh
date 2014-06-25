#!/bin/sh

. pgcommon.sh

MYTBL=t

usage ()
{
cat <<EOF
$PROGNAME creates a simple table.

Usage:
  $PROGNAME
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation

cat <<EOF | $PGBIN/psql postgres
DROP TABLE ${MYTBL} ;
CREATE TABLE ${MYTBL} AS SELECT x i, x * 10 + x j FROM generate_series(1, 10) x ;
SELECT * FROM ${MYTBL} ;
EOF
