#!/bin/sh

. pgcommon.sh

MYTBL=t
MYSEQ=${MYTBL}_seq
NUMJOBS=1
NUMROWS=10
NUMPARTS=0
LOADPIDS=()
APPENDROWS="FALSE"
NUMCACHE=1000
MYTBLSPC=
TBLSPCOPT=

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
  -T TBLSPC   creates tablespace if not exists, and places tables there
  -p NUM      partition table into NUM parts (default: 0)
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
		-T)
			MYTBLSPC=$2
			shift;;
		-p)
			NUMPARTS=$2
			shift;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

function create_tablespace ()
{
	if [ "${MYTBLSPC}" = "" ]; then
		return
	fi

	TBLSPCOPT="TABLESPACE ${MYTBLSPC}"
	cat <<EOF | $PSQL
DROP TABLESPACE IF EXISTS ${MYTBLSPC};
\! test -d ${CURDIR}/${MYTBLSPC} || mkdir ${CURDIR}/${MYTBLSPC}
CREATE TABLESPACE ${MYTBLSPC} LOCATION '${CURDIR}/${MYTBLSPC}';
EOF
}

function prepare_table ()
{
	cat <<EOF | $PSQL
DROP SEQUENCE IF EXISTS ${MYSEQ};
DROP TABLE IF EXISTS ${MYTBL} ;
CREATE SEQUENCE ${MYSEQ} CACHE ${NUMCACHE};
EOF
}

function create_table ()
{
	cat <<EOF | $PSQL
CREATE TABLE ${MYTBL} (i INT, j INT) ${TBLSPCOPT};
EOF
}

function create_partition ()
{
	TOTALROWS=$(echo "${NUMJOBS} * ${NUMROWS}" | bc)
	if [ $TOTALROWS -lt $NUMPARTS ]; then
		NUMPARTS=$TOTALROWS
	fi
	DELTA=$(echo "${TOTALROWS} / ${NUMPARTS}" | bc)
	PARTID=0
	LOWERVAL=1
	UPPERVAL=1
	cat <<EOF | $PSQL
CREATE TABLE ${MYTBL} (i INT, j INT) PARTITION BY range (i) ${TBLSPCOPT};
EOF
	while [ $PARTID -lt $NUMPARTS ]; do
		UPPERVAL=$(echo "$LOWERVAL + $DELTA" | bc)
		cat <<EOF | $PSQL
CREATE TABLE ${MYTBL}_${PARTID} PARTITION OF ${MYTBL}
  FOR VALUES FROM (${LOWERVAL}) TO (${UPPERVAL}) ${TBLSPCOPT};
EOF
		LOWERVAL=$UPPERVAL
		PARTID=$(expr $PARTID + 1)
	done
	cat <<EOF | $PSQL
CREATE TABLE ${MYTBL}_max PARTITION OF ${MYTBL}
  FOR VALUES FROM (${LOWERVAL}) TO (MAXVALUE) ${TBLSPCOPT};
CREATE TABLE ${MYTBL}_default PARTITION OF ${MYTBL} DEFAULT ${TBLSPCOPT};
EOF
}

function prepare_append ()
{
	cat <<EOF | $PSQL
ALTER SEQUENCE ${MYSEQ} CACHE ${NUMCACHE};
EOF
}

function load_rows ()
{
	cat <<EOF | $PSQL
INSERT INTO ${MYTBL}
  SELECT nextval('${MYSEQ}'), n FROM generate_series(1, ${NUMROWS}) n;
EOF
}

here_is_installation
pgdata_exists
pgsql_is_alive

prepare_psql

if [ $NUMROWS -ge 1 -a $NUMROWS -lt $NUMCACHE ]; then
   NUMCACHE=$NUMROWS
fi

if [ "$APPENDROWS" = "FALSE" ]; then
	prepare_table
	create_tablespace
	if [ $NUMPARTS -eq 0 ]; then
		create_table
	else
		create_partition
	fi
else
	prepare_append
fi

[ $NUMROWS -lt 1 ] && exit 0

for JOB in $(seq 1 ${NUMJOBS}); do
	load_rows &
	LOADPIDS+=($!)
done

for LOADPID in ${LOADPIDS[@]}; do
	wait ${LOADPID}
done
