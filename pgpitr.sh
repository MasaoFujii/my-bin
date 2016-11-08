#!/bin/sh

. pgcommon.sh

PGPITR_DONE=pgpitr.done

usage ()
{
cat <<EOF
$PROGNAME prepares for an archive recovery

Usage:
  $PROGNAME [PGDATA]

Description:
  This utility restores a base backup and creates recovery.conf.
  This must be called after a base backup has been taken.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
validate_archiving
pgdata_exists
pgsql_is_dead

if [ ! -d $PGDATABKP ]; then
	elog "base backup is not found: \"$PGDATABKP\""
fi

if [ ! -d $PGARCH ]; then
	echo "archive directory is not found: \"$PGARCH\""
fi

if [ ! -f $PGDATABKP/$PGPITR_DONE ]; then
	RESTORECMD="cp ../$(basename $PGARCH)/%f %p"
	echo "restore_command = '${RESTORECMD}'" > $PGDATABKP/$RECFILENAME

	rm -rf $PGDATABKP/pg_xlog $PGDATABKP/pg_wal
	mv $PGXLOG $PGDATABKP

	pgrsync.sh $PGARCH $PGARCHBKP

	touch $PGDATABKP/$PGPITR_DONE
else
	pgrsync.sh $PGARCHBKP $PGARCH
fi

pgrsync.sh $PGDATABKP $PGDATA
rm -f $PGDATA/$PGPITR_DONE
