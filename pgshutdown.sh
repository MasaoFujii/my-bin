#!/bin/sh

CURDIR=$(pwd)
PROGNAME=$(basename ${0})

usage ()
{
    echo "${PROGNAME} shuts down the pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Default:"
    echo "  fires a smart shutdown"
    echo ""
    echo "Options:"
    echo "  -D        location of \$PGDATA"
    echo "  -f        fires a fast shutdown"
    echo "  -h        shows this help, then exits"
    echo "  -i        fires an immediate shutdown"
    echo "  -s        fires a smart shutdown"
}

PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data

if [ ! -f ${PGBIN}/pg_config ]; then
    echo "ERROR: invalid present location"
    echo "HINT : you need to move to pgsql installation directory"
    exit 1
fi

SHUTDOWN_MODE="s"
while getopts "D:fhis" OPT; do
    case ${OPT} in
	D)
	    PGDATA=${OPTARG}
	    ;;
	f)
	    SHUTDOWN_MODE="f"
	    ;;
	h)
	    usage
	    exit 0
	    ;;
	i)
	    SHUTDOWN_MODE="i"
	    ;;
	s)
	    SHUTDOWN_MODE="s"
	    ;;
    esac
done

if [ ! -d ${PGDATA} ]; then
    echo "ERROR: \$PGDATA is not found: ${PGDATA}"
    exit 1
fi

${PGBIN}/pg_ctl -D ${PGDATA} -m${SHUTDOWN_MODE} stop
