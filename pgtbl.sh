#!/bin/sh

. pgcommon.sh

MYTBL=t
MYSEQ=${MYTBL}_seq
NUMJOBS=1
NUMROWS=10
LOADPIDS=()

usage ()
{
cat <<EOF
$PROGNAME creates a simple table.

Usage:
  $PROGNAME [OPTIONS] [PGDATA]

Options:
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

cat <<EOF | $PSQL
DROP SEQUENCE ${MYSEQ};
DROP TABLE ${MYTBL} ;
CREATE SEQUENCE ${MYSEQ} CACHE ${NUMROWS};
CREATE TABLE ${MYTBL} (i INT, j INT);
EOF

function load_rows ()
{
	cat <<EOF | $PSQL
INSERT INTO ${MYTBL} SELECT x, x % ${NUMROWS} FROM
	(SELECT nextval('${MYSEQ}') AS x FROM
	generate_series(1, ${NUMROWS})) hoge;
EOF
}

for JOB in $(seq 1 ${NUMJOBS}); do
	load_rows &
	LOADPIDS+=($!)
done

for LOADPID in ${LOADPIDS[@]}; do
	wait ${LOADPID}
done
