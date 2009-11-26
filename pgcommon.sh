#!/bin/sh

# Common global variables
CURDIR=$(pwd)
PROGNAME=$(basename ${0})
TMPFILE=/tmp/pgscript_$(date +%Y%m%d%H%M%S).tmp
PGMAJOR=
TEMPLATEDB=template1

# Directories of pgsql
PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data
PGARCH=${PGDATA}.arch
PGARCHNAME=$(basename ${PGARCH})
PGXLOG=${PGDATA}/pg_xlog
PGARCHSTATUS=${PGXLOG}/archive_status
PGDATABKP=${PGDATA}.bkp
PGARCHBKP=${PGARCH}.bkp
PGCONF=${PGDATA}/postgresql.conf
PGHBA=${PGDATA}/pg_hba.conf
RECOVERYCONF=${PGDATA}/recovery.conf

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
    PGARCHNAME=$(basename ${PGARCH})
    PGXLOG=${PGDATA}/pg_xlog
    PGARCHSTATUS=${PGXLOG}/archive_status
    PGDATABKP=${PGDATA}.bkp
    PGARCHBKP=${PGARCH}.bkp
    PGCONF=${PGDATA}/postgresql.conf
    PGHBA=${PGDATA}/pg_hba.conf
    RECOVERYCONF=${PGDATA}/recovery.conf
}

# Validate that $PGDATA is found.
ValidatePgData ()
{
    if [ ! -d ${PGDATA} ]; then
	echo "ERROR: \$PGDATA is not found: ${PGDATA}"
	exit 1
    fi
}

# WAL archiving is supported?
# NOTE: CurDirIsPgsqlIns must be done before calling this.
ArchivingIsSupported ()
{
    if [ ${PGMAJOR} -lt 80 ]; then
	echo "ERROR: WAL archiving is not supported in this pgsql version"
	exit 1
    fi
}

# Pgsql must be running. Exit otherwise.
PgsqlMustRunning ()
{
    ${PGBIN}/pg_ctl -D ${PGDATA} status > /dev/null
    if [ ${?} -ne 0 ]; then
	echo "ERROR: pgsql must be running; start up pgsql right now"
	exit 1
    fi
}

# Pgsql must not be running. Exit otherwise.
PgsqlMustNotRunning ()
{
    ${PGBIN}/pg_ctl -D ${PGDATA} status > /dev/null
    if [ ${?} -eq 0 ]; then
	echo "ERROR: pgsql must NOT be running; shut down pgsql right now"
	exit 1
    fi
}

# Wait until target file has been archived.
# NOTE: target file *NAME* must be passed in the first argument.
WaitFileArchived ()
{
    # Get target file name
    if [ ${#} -lt 1 ]; then
	echo "ERROR: target file name must be supplied"
	exit 1
    fi
    TARGETFILE=${1}

    # archive_status file of target
    READYFILE=${PGARCHSTATUS}/${TARGETFILE}.ready
    DONEFILE=${PGARCHSTATUS}/${TARGETFILE}.done

    while [ 1 ]; do
	# Regarded as archived if .done exists in archive_status
	if [ -f ${DONEFILE} ]; then
	    return
	fi

	# Regarded as archived if .ready doesn't exist in archive_status
	# and target file itself doesn't exist in pg_xlog.
	if [ ! -f ${READYFILE} -a ! -f ${PGXLOG}/${TARGETFILE} ]; then
	    return
	fi

	# Sleep 1 sec
	sleep 1
    done
}

# Wait until startup of pgsql has been completed,
# i.e., pgsql has been brought up.
WaitForPgsqlStartup ()
{
	while [ 1 ]; do
		${PGBIN}/psql -l ${TEMPLATEDB} > /dev/null 2>&1
		if [ ${?} -eq 0 ]; then
			return
		fi

		sleep 1
	done
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

# Set one GUC in postgresql.conf
# NOTE: arguments are a GUC name, value, and conf path.
SetOneGuc ()
{
    if [ ${#} -lt 3 ]; then
	echo "ERROR: \"GUC name\", \"value\" and \"conf path\" must be supplied"
	exit 1
    fi
    GUCNAME=${1}
    GUCVALUE=${2}
    CONFPATH=${3}

    # Remove old GUC setting, and add new one
    RemoveLineFromFile "^${GUCNAME}" ${CONFPATH}
    echo "${GUCNAME} = ${GUCVALUE}" >> ${CONFPATH}
}
