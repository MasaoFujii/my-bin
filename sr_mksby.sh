#!/bin/sh

ACT=act
ACTBKP=act.bkp
SBY=sby
SBYCONF=$SBY/postgresql.conf
RCONF=$SBY/recovery.conf

rm -rf trigger $ACTBKP $SBY
pgbackup.sh $ACT
mv $ACTBKP $SBY
echo "port = 5433" >> $SBYCONF
echo "log_line_prefix = 'sby [%p] '" >> $SBYCONF
echo "standby_mode = 'on'" >> $RCONF
echo "trigger_file = '../trigger'" >> $RCONF
pgstart.sh $SBY
