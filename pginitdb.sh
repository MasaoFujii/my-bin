#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local functions
Usage ()
{
    echo "${PROGNAME} creates an initial database cluster"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
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

rm -rf ${PGDATA}
${PGBIN}/initdb -D ${PGDATA} --no-locale --encoding=UTF8

echo "host all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf
echo "listen_addresses = '*'"       >> ${PGDATA}/postgresql.conf
echo "checkpoint_segments = 64"     >> ${PGDATA}/postgresql.conf
