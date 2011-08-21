#!/bin/sh

. pgcommon.sh

ARCHIVE_MODE="FALSE"

usage ()
{
	echo "$PROGNAME initializes PGDATA."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] [PGDATA]"
	echo ""
	echo "Options:"
	echo "  -a    enables WAL archiving"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			ARCHIVE_MODE="TRUE";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgsql_is_dead

rm -rf $PGDATA
$PGBIN/initdb -D $PGDATA --locale=C --encoding=UTF8

if [ $PGMAJOR -le 74 ]; then
	set_guc tcpip_socket true $PGCONF
else
	set_guc listen_addresses "'*'" $PGCONF
fi
set_guc checkpoint_segments 64 $PGCONF
echo "host	all	all	0.0.0.0/0	trust" >> $PGHBA

if [ "$ARCHIVE_MODE" = "TRUE" ]; then
	pgarch.sh $PGDATA
fi
