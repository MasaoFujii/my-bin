#!/bin/sh

. pgcommon.sh

usage ()
{
cat <<EOF
$PROGNAME shows current WAL location.

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

$PGBIN/psql -c "SELECT pg_current_xlog_location()" postgres
