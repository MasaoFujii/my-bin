#!/bin/sh

. pgcommon.sh

ARCHIVE_MODE="FALSE"
CHECKSUM=""
XLOGDIR=""
AUTOTUNE="FALSE"

usage ()
{
cat <<EOF
$PROGNAME initializes PGDATA.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -a    enables WAL archiving
  -k    uses data page checksums
  -T    uses auto tuning
  -X    uses external XLOG directory
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			ARCHIVE_MODE="TRUE";;
		-k)
			CHECKSUM="-k";;
		-T)
			AUTOTUNE="TRUE";;
		-X)
			XLOGDIR="-X $CURDIR/$PGXLOGEXT";;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgsql_is_dead
validate_datapage_checksums "$CHECKSUM"

rm -rf $PGDATA
$PGBIN/initdb -D $PGDATA --locale=C --encoding=UTF8 $CHECKSUM $XLOGDIR
exit_on_error

if [ $PGMAJOR -le 74 ]; then
	set_guc tcpip_socket true $PGCONF
else
	set_guc listen_addresses "'*'" $PGCONF
fi
set_guc checkpoint_segments 256 $PGCONF
set_guc max_wal_size 512 $PGCONF
set_guc log_line_prefix "'%t '" $PGCONF
#set_guc log_checkpoints on $PGCONF
#set_guc log_error_verbosity verbose $PGCONF
set_guc wal_sync_method fdatasync $PGCONF
echo "host	all	all	0.0.0.0/0	trust" >> $PGHBA

if [ "$ARCHIVE_MODE" = "TRUE" ]; then
	pgarch.sh $PGDATA
fi

if [ "$AUTOTUNE" = "TRUE" ]; then
	pgconf.sh -T $PGDATA
fi
