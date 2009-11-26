#!/bin/sh

# Common global variables
CURDIR=$(pwd)
PROGNAME=$(basename ${0})
TMPFILE=/tmp/pgscript_$(date +%Y%m%d%H%M%S).tmp
PGMAJOR=

# Directories of pgsql
PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data
PGARCH=${PGDATA}.arch
PGXLOG=${PGDATA}/pg_xlog
PGARCHSTATUS=${PGXLOG}/archive_status
PGCONF=${PGDATA}/postgresql.conf
PGHBA=${PGDATA}/pg_hba.conf

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

    # Get the pgsql major version
    PGMAJOR=$(${PGBIN}/pg_config --version | tr --delete [A-z.' '] | cut -c1-2)
}

# Get the path of $PGDATA from the first commad-line argument.
# NOTE: "${@}" should be passed as an argument.
GetPgData ()
{
    if [ ${#} -gt 0 ]; then
	PGDATA=${1}
    fi

    # The following paths are derived from $PGDATA
    PGARCH=${PGDATA}.arch
    PGXLOG=${PGDATA}/pg_xlog
    PGARCHSTATUS=${PGXLOG}/archive_status
    PGCONF=${PGDATA}/postgresql.conf
    PGHBA=${PGDATA}/pg_hba.conf
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

# Remove the line matching the specified regular expression regexp from the file.
# NOTE: The regular expression regexp must be passed as the first argument.
# NOTE: The path of target file must be passed as the second argument.
RemoveLineFromFile ()
{
    if [ ${#} -lt 2 ]; then
	echo "ERROR: regexp and filepath must be supplied"
	exit 1
    fi

    REGEXP="${1}"
    TARGETFILE=${2}

    sed /"${REGEXP}"/D ${TARGETFILE} > ${TMPFILE}
    mv ${TMPFILE} ${TARGETFILE}
}
