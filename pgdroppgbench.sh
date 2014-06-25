#!/bin/sh

. pgcommon.sh

usage ()
{
cat <<EOF
$PROGNAME drops any pgbench objects.

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

$PGBIN/psql -c "DROP TABLE pgbench_accounts CASCADE;" postgres
$PGBIN/psql -c "DROP TABLE pgbench_branches CASCADE;" postgres
$PGBIN/psql -c "DROP TABLE pgbench_tellers CASCADE;" postgres
$PGBIN/psql -c "DROP TABLE pgbench_history CASCADE;" postgres
