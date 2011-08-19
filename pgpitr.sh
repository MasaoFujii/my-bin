#!/bin/sh

. pgcommon

usage ()
{
	echo "$PROGNAME prepares for an archive recovery"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [PGDATA]"
	echo ""
	echo "Description:"
	echo "  This utility restores a base backup and creates recovery.conf."
	echo "  This must be called after a base backup has been taken."
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
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
archiving_is_supported
pgdata_exists
pgsql_is_dead

if [ ! -d $PGDATABKP ]; then
	elog "base backup is not found: \"$PGDATABKP\""
fi

if [ ! -d $PGARCH ]; then
	echo "archive directory is not found: \"$PGARCH\""
fi

RESTORECMD="cp ../$(basename $PGARCH)/%f %p"
echo "restore_command = '${RESTORECMD}'" > $PGDATABKP/recovery.conf

rm -rf $PGDATABKP/pg_xlog
mv $PGDATA/pg_xlog $PGDATABKP

rm -rf $PGDATA
cp -r $PGDATABKP $PGDATA

rm -rf $PGARCHBKP
cp -r $PGARCH $PGARCHBKP
