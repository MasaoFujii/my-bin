#!/bin/sh

CURDIR=$(pwd)
PROGNAME=$(basename ${0})

usage ()
{
    echo "${PROGNAME} starts the pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -D        location of \$PGDATA"
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

${PGBIN}/pg_ctl -D ${PGDATA} start
