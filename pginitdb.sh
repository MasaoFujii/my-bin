#!/bin/sh

CURDIR=$(pwd)
PROGNAME=$(basename ${0})

usage ()
{
    echo "${PROGNAME} creates an initial \$PGDATA"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -D        location of \$PGDATA"
    echo "  -h        shows this help, then exits"
}

PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data

if [ ! -f ${PGBIN}/pg_config ]; then
    echo "ERROR: invalid present location"
    echo "HINT : you need to move to pgsql installation directory"
    exit 1
fi

while getopts "D:h" OPT; do
    case ${OPT} in
	D)
	    PGDATA=${OPTARG}
	    ;;
	h)
	    usage
	    exit 0
	    ;;
    esac
done

if [ ! -d ${PGDATA} ]; then
    echo "ERROR: \$PGDATA is not found: ${PGDATA}"
    exit 1
fi

rm -rf ${PGDATA}
${PGBIN}/initdb -D $PGDATA --no-locale --encoding=UTF8

echo "host all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf
echo "listen_addresses = '*'"       >> ${PGDATA}/postgresql.conf
echo "checkpoint_segments = 64"     >> ${PGDATA}/postgresql.conf
