#!/bin/sh

. pgcommon.sh

PUBDATA=data
SUBDATA=sub1
SBYDATA=sby1

PUBPORT=5432
SUBPORT=5433    ## 5434 if --slotsync
SBYPORT=5433

SUBCONN="port=$PUBPORT"
SUBOPT=

SLOTSYNC=false

usage ()
{
cat <<EOF
$PROGNAME sets up the publisher and subscriber for logical replication.

Usage:
  $PROGNAME [OPTIONS]

Options:
  --slotsync  uses replication slot sync
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		--slotsync)
			SLOTSYNC=true;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation
pgsql_is_dead
validate_logical_replication

if [ "$SLOTSYNC" = "false" ]; then
	pginitdb.sh $PUBDATA
	exit_on_error
	pgstart.sh -w $PUBDATA
else
	pgsr.sh --slot
	pgconf.sh -c sync_replication_slots on $SBYDATA
	pgconf.sh -c hot_standby_feedback on $SBYDATA
	PREVCONNINFO=$(pgconf.sh -s primary_conninfo $SBYDATA)
	pgconf.sh -c primary_conninfo "'$PREVCONNINFO dbname=postgres'" $SBYDATA
	pgconf.sh -c synchronized_standby_slots "'$SBYDATA'" $ACTDATA
	pgreload.sh $SBYDATA
	pgreload.sh $ACTDATA
	SUBPORT=5434
	SUBCONN="host=localhost,localhost port=${PUBPORT},${SBYPORT} target_session_attrs=primary"
	SUBOPT="WITH (failover = 'true')"
	$PGBIN/psql -p $SBYPORT -c "SELECT pg_create_physical_replication_slot('$SBYDATA')"
fi

pginitdb.sh $SUBDATA
exit_on_error
pgconf.sh -c port $SUBPORT $SUBDATA
pgstart.sh -w $SUBDATA

pgtbl.sh -n 0 $PUBDATA
cat <<EOF | $PGBIN/psql
ALTER TABLE t ADD PRIMARY KEY (i);
ALTER TABLE t REPLICA IDENTITY DEFAULT;
CREATE PUBLICATION tpub FOR TABLE t;
EOF

pgtbl.sh -n 0 $SUBDATA
cat <<EOF | $PGBIN/psql -p $SUBPORT
ALTER TABLE t ADD PRIMARY KEY (i);
CREATE SUBSCRIPTION tsub CONNECTION '${SUBCONN}' PUBLICATION tpub $SUBOPT;
EOF
