#!/bin/sh

. pgcommon.sh

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
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

if [ ! -d $PGDATA ]; then
	echo "$PROGNAME: database cluster is not found: \"$PGDATA\"" 1>&2
	exit 1
fi

PgsqlMustNotRunning

if [ ! -d $PGDATABKP ]; then
	echo "$PROGNAME: base backup is not found: \"$PGDATABKP\"" 1>&2
	exit 1
fi

if [ ! -d $PGARCH ]; then
	echo "$PROGNAME: archive directory is not found: \"$PGARCH\"" 1>&2
	exit 1
fi

RESTORECMD="cp ../$(basename $PGARCH)/%f %p"
echo "restore_command = '${RESTORECMD}'" > $PGDATABKP/recovery.conf

rm -rf $PGDATABKP/pg_xlog
mv $PGDATA/pg_xlog $PGDATABKP

rm -rf $PGDATA
cp -r $PGDATABKP $PGDATA

rm -rf $PGARCHBKP
cp -r $PGARCH $PGARCHBKP
