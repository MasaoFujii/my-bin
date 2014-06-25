#!/bin/sh

. pgcommon.sh

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

$PGBIN/psql -c "CREATE TABLE t (i int, j int); INSERT INTO t VALUES (1, 11), (2, 22), (3, 33)" postgres
