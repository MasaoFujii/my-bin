#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local functions
Usage ()
{
    echo "${PROGNAME} starts pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

while getopts "h" OPT; do
    case ${OPT} in
	h)
	    Usage
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
