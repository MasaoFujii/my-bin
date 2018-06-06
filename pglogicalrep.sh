#!/bin/sh

. pgcommon.sh

PUBDATA=pub
SUBDATA=sub

usage ()
{
cat <<EOF
$PROGNAME sets up the publisher and subscriber for logical replication.

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
pgsql_is_dead
validate_logical_replication

pginitdb.sh $PUBDATA
exit_on_error

pgconf.sh -c wal_level logical $PUBDATA
pgconf.sh -c log_line_prefix "'%t pub [%p] '" $PUBDATA
pgstart.sh -w $PUBDATA

pginitdb.sh $SUBDATA
exit_on_error

pgconf.sh -c port 5433 $SUBDATA
pgconf.sh -c log_line_prefix "'%t sub [%p] '" $SUBDATA
pgstart.sh -w $SUBDATA

cat <<EOF | $PGBIN/psql
CREATE TABLE test (i INT PRIMARY KEY, j INT);
ALTER TABLE test REPLICA IDENTITY DEFAULT;
CREATE PUBLICATION testpub FOR TABLE test;
EOF

cat <<EOF | $PGBIN/psql -p 5433
CREATE TABLE test (i INT PRIMARY KEY, j INT);
CREATE SUBSCRIPTION testsub CONNECTION '' PUBLICATION testpub;
EOF
