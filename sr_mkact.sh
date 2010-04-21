#!/bin/sh

ACT=act
ACTCONF=$ACT/postgresql.conf
ACTHBA=$ACT/pg_hba.conf

pginitdb.sh $ACT
pgarch.sh $ACT
echo "max_wal_senders = 5" >> $ACTCONF
echo "log_line_prefix = 'act [%p] '" >> $ACTCONF
echo "host replication all 0.0.0.0/0 trust" >> $ACTHBA
pgstart.sh -w $ACT
