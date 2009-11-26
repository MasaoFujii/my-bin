#!/bin/sh

# Common global variables
CURDIR=$(pwd)
PROGNAME=$(basename ${0})
TMPFILE=/tmp/pgscript_$(date +%Y%m%d%H%M%S).tmp

# Directories of pgsql
PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data

# Current location is pgsql source dir?
CurDirIsPgsqlSrc ()
{
    if [ ! -f ${CURDIR}/configure ]; then
	echo "ERROR: invalid current location; move to pgsql source directory"
	exit 1
    fi
}

# Current location is pgsql installation dir?
CurDirIsPgsqlIns ()
{
    if [ ! -f ${PGBIN}/pg_config ]; then
	echo "ERROR: invalid current location; move to pgsql installation directory"
	exit 1
    fi
}

# Get the path of $PGDATA from the first commad-line argument.
# NOTE: "${@}" should be passed as an argument.
GetPgData ()
{
    if [ ${#} -gt 0 ]; then
	PGDATA=${1}
    fi
}

# Validate that $PGDATA is found.
ValidatePgData ()
{
    if [ ! -d ${PGDATA} ]; then
	echo "ERROR: \$PGDATA is not found: ${PGDATA}"
	exit 1
    fi
}

# Parse only -h option.
# NOTE: "${@}" should be passed as an argument.
# NOTE: The function "Usage" should be define before calling this.
ParseHelpOption ()
{
    while getopts "h" OPT; do
	case ${OPT} in
	    h)
		Usage
		exit 0
		;;
	esac
    done
    shift $(expr ${OPTIND} - 1)
}
