#!/bin/sh

ACT=act
ACTCONF=$ACT/postgresql.conf

pginitdb.sh $ACT
pgarch.sh $ACT
echo "max_wal_senders = 5" >> $ACTCONF
echo "log_line_prefix = 'act [%p] '" >> $ACTCONF
pgstart.sh -w $ACT
