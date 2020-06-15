#!/bin/sh

. pgcommon.sh

PUBDATA=data
SUBDATA=sub1

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
pgconf.sh -c log_line_prefix "'$LOGLINEPREFIX $PUBDATA [%p] '" $PUBDATA
pgstart.sh -w $PUBDATA

pginitdb.sh $SUBDATA
exit_on_error

pgconf.sh -c port 5433 $SUBDATA
pgconf.sh -c log_line_prefix "'$LOGLINEPREFIX $SUBDATA [%p] '" $SUBDATA
pgstart.sh -w $SUBDATA

pgtbl.sh -n 0 $PUBDATA
cat <<EOF | $PGBIN/psql
ALTER TABLE t ADD PRIMARY KEY (i);
ALTER TABLE t REPLICA IDENTITY DEFAULT;
CREATE PUBLICATION tpub FOR TABLE t;
EOF

pgtbl.sh -n 0 $SUBDATA
cat <<EOF | $PGBIN/psql -p 5433
ALTER TABLE t ADD PRIMARY KEY (i);
CREATE SUBSCRIPTION tsub CONNECTION '' PUBLICATION tpub;
EOF
