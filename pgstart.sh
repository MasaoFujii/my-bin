#!/bin/sh

CURDIR=$(pwd)
PROGNAME=$(basename ${0})

usage ()
{
    echo "${PROGNAME} starts the pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data

if [ ! -f ${PGBIN}/pg_config ]; then
    echo "ERROR: invalid present location"
    echo "HINT : you need to move to pgsql installation directory"
    exit 1
fi

while getopts "h" OPT; do
    case ${OPT} in
	h)
	    usage
	    exit 0
	    ;;
    esac
done

shift $(expr ${OPTIND} - 1)

if [ ${#} -gt 0 ]; then
    PGDATA=${1}
fi

if [ ! -d ${PGDATA} ]; then
    echo "ERROR: \$PGDATA is not found: ${PGDATA}"
    exit 1
fi

${PGBIN}/pg_ctl -D ${PGDATA} start
