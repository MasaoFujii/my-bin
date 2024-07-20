#!/bin/sh

. pgcommon.sh

MYTBL=t
MYSEQ=${MYTBL}_seq
NUMJOBS=1
NUMROWS=10
LOADPIDS=()
APPENDROWS="FALSE"
NUMCACHE=1000

usage ()
{
cat <<EOF
$PROGNAME creates a table and loads rows into it.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
  -a          appends rows into existing table
  -j NUM      number of jobs loading rows (default: 1)
  -n NUM      number of rows that each job loads (default: 10)
  -t TABLE    name of table to create (default: 't')
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			APPENDROWS="TRUE";;
		-j)
			NUMJOBS=$2
			shift;;
		-n)
			NUMROWS=$2
			shift;;
		-t)
			MYTBL=$2
			MYSEQ=${MYTBL}_seq
			shift;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists
pgsql_is_alive

prepare_psql

if [ $NUMROWS -ge 1 -a $NUMROWS -lt $NUMCACHE ]; then
   NUMCACHE=$NUMROWS
fi

if [ "$APPENDROWS" = "FALSE" ]; then
  cat <<EOF | $PSQL
DROP SEQUENCE ${MYSEQ};
DROP TABLE ${MYTBL} ;
CREATE SEQUENCE ${MYSEQ} CACHE ${NUMCACHE};
CREATE TABLE ${MYTBL} (i INT, j INT);
EOF
else
  cat <<EOF | $PSQL
ALTER SEQUENCE ${MYSEQ} CACHE ${NUMCACHE};
EOF
fi

[ $NUMROWS -lt 1 ] && exit 0

function load_rows ()
{
	cat <<EOF | $PSQL
INSERT INTO ${MYTBL}
  SELECT nextval('${MYSEQ}'), n FROM generate_series(1, ${NUMROWS}) n;
EOF
}

for JOB in $(seq 1 ${NUMJOBS}); do
	load_rows &
	LOADPIDS+=($!)
done

for LOADPID in ${LOADPIDS[@]}; do
	wait ${LOADPID}
done
