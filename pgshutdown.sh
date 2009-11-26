#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local functions
Usage ()
{
    echo "${PROGNAME} shuts down pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Default:"
    echo "  performs a smart shutdown"
    echo ""
    echo "Options:"
    echo "  -f        performs a fast shutdown"
    echo "  -h        shows this help, then exits"
    echo "  -i        performs an immediate shutdown"
    echo "  -s        performs a smart shutdown"
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

SHUTDOWN_MODE="s"
while getopts "fhis" OPT; do
    case ${OPT} in
	f)
	    SHUTDOWN_MODE="f"
	    ;;
	h)
	    Usage
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

shift $(expr ${OPTIND} - 1)

if [ ${#} -gt 0 ]; then
    PGDATA=${1}
fi

if [ ! -d ${PGDATA} ]; then
    echo "ERROR: \$PGDATA is not found: ${PGDATA}"
    exit 1
fi

${PGBIN}/pg_ctl -D ${PGDATA} -m${SHUTDOWN_MODE} stop
