#!/bin/sh

# Load common definitions
. pgcommon.sh

# Local variables
BACKUP_PGARCH="FALSE"
BACKUP_PGXLOG="FALSE"
STARTLSN=
STOPLSN=
PGDATABKP_SUPPLY=
PGARCHBKP_SUPPLY=

# Show usage
Usage ()
{
    echo "${PROGNAME} creates base backup"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Default:"
    echo "  takes backup of $PGDATA"
    echo ""
    echo "Options:"
    echo "  -a        also takes backup of archive directory"
    echo "  -A PATH   specifies path of archive directory backup"
    echo "  -D PATH   specifies path of database cluster backup"
    echo "  -h        shows this help, then exits"
    echo "  -x        also takes backup of pg_xlog"
}

# Take base backup of $PGDATA
BackupPgData ()
{
    # Determine the arguments of pg_start_backup
    STARTBKPARGS="${PROGNAME}"
    if [ ${PGMAJOR} -ge 84 ]; then
	STARTBKPARGS="${STARTBKPARGS}, true"
    fi

    # Determine the SQL statement of pg_start_backup
    STARTBKPSQL="SELECT pg_xlogfile_name(pg_start_backup('${STARTBKPARGS}'))"
    if [ ${PGMAJOR} -eq 83 ]; then
	STARTBKPSQL="CHECKPOINT; ${STARTBKPSQL}"
    fi

    # Determine the SQL statement of pg_stop_backup
    STOPBKPSQL="SELECT pg_xlogfile_name(pg_stop_backup())"

    # Determine rsync's exclusion list
    EXCLUDELIST="--exclude=postmaster.pid"
    if [ "${BACKUP_PGXLOG}" = "FALSE" ]; then
	EXCLUDELIST="${EXCLUDELIST} --exclude=pg_xlog"
    fi

    # Delete old backup of $PGDATA
    if [ ! -z "${PGDATABKP_SUPPLY}" ]; then
	PGDATABKP=${PGDATABKP_SUPPLY}
    fi
    rm -rf ${PGDATABKP}

    # Take base backup
    STARTLSN=$(${PGBIN}/psql -Atc "${STARTBKPSQL}" ${TEMPLATEDB})
    if [ ${?} -ne 0 ]; then
	exit 1
    fi
    rsync -a ${EXCLUDELIST} ${PGDATA}/ ${PGDATABKP}
    STOPLSN=$(${PGBIN}/psql -Atc "${STOPBKPSQL}" ${TEMPLATEDB})

    # Create pg_xlog and archive_status if they are not in backup
    if [ "${BACKUP_PGXLOG}" = "FALSE" ]; then
	mkdir -p ${PGDATABKP}/pg_xlog/archive_status
    fi
}

# Take backup of archive directory
BackupPgArch ()
{
    if [ "${BACKUP_PGARCH}" = "FALSE" ]; then
	return
    fi

    # Delete old backup of archive directory
    if [ ! -z "${PGARCHBKP_SUPPLY}" ]; then
	PGARCHBKP=${PGARCHBKP_SUPPLY}
    fi
    rm -rf ${PGARCHBKP}

    # Wait until backup history file and last WAL file have been archived
    if [ ${PGMAJOR} -le 83 ]; then
	BACKUP_HISTORY="${STARTLSN}.*.backup"
	LAST_WALFILE="${STOPLSN}"
	WaitFileArchived ${BACKUP_HISTORY}
	WaitFileArchived ${LAST_WALFILE}
    fi

    # Take backup of archive directory
    rsync -a ${PGARCH}/ ${PGARCHBKP}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
while getopts "aA:D:hx" OPT; do
    case ${OPT} in
	a)
	    BACKUP_PGARCH="TRUE"
	    ;;
	A)
	    PGARCHBKP_SUPPLY=${OPTARG}
	    ;;
	D)
	    PGDATABKP_SUPPLY=${OPTARG}
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
	x)
	    BACKUP_PGXLOG="TRUE"
	    ;;
    esac
done
shift $(expr ${OPTIND} - 1)

# Get and validate $PGDATA
GetPgData ${@}
ValidatePgData

# WAL archiving must be supported in this pgsql version
ArchivingIsSupported

# Pgsql must be running
PgsqlMustRunning

# Take backup
BackupPgData
BackupPgArch
