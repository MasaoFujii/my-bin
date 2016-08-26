#!/bin/sh

. pgcommon.sh

usage ()
{
cat <<EOF
$PROGNAME enables WAL archiving.

Usage:
  $PROGNAME [PGDATA]

Description:
  This utility sets up the configuration parameters related to WAL archiving
  and creates the archival directory.
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

if [ ! -d $PGDATA ]; then
	pginitdb.sh
fi

pgsql_is_dead

rm -rf $PGARCH
mkdir $PGARCH

if [ $PGMAJOR -ge 90 ]; then
	set_guc wal_level hot_standby $PGCONF
fi

if [ $PGMAJOR -ge 83 ]; then
	set_guc archive_mode on $PGCONF
fi

set_guc archive_command "'cp %p ../$(basename $PGARCH)/%f'" $PGCONF
