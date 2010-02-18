#!/bin/sh

# Load common definitions
. pgcommon.sh

# Local variables
PGARCH_SUPPLY=

# Show usage
Usage ()
{
    echo "${PROGNAME} enables WAL archiving"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -A PATH   specifies archive directory path"
    echo "  -h        shows this help, then exits"
}

# Enable WAL archiving
EnableWALArchiving ()
{
    if [ ${PGMAJOR} -ge 83 ]; then
			set_guc archive_mode on ${PGCONF}
    fi

    set_guc archive_command "'cp %p ../${PGARCHNAME}/%f'" ${PGCONF}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
while getopts "A:h" OPT; do
    case ${OPT} in
	A)
	    PGARCH_SUPPLY=${OPTARG}
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
    esac
done
shift $(expr ${OPTIND} - 1)

# Get and validate $PGDATA
GetPgData ${@}
ValidatePgData

# WAL archiving must be supported in this pgsql version
ArchivingIsSupported

# Create new archive directory
if [ ! -z "${PGARCH_SUPPLY}" ]; then
    PGARCH=${PGARCH_SUPPLY}
    PGARCHNAME=$(basename ${PGARCH})
fi
rm -rf ${PGARCH}
mkdir ${PGARCH}

# Enable WAL archiving
EnableWALArchiving
