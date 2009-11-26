#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Show usage
Usage ()
{
    echo "${PROGNAME} enables WAL archiving"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Check that WAL archiving is supported
WALArchivingIsSupported ()
{
    if [ ${PGMAJOR} -lt 80 ]; then
	echo "ERROR: WAL archiving is not supported in this pgsql version"
	exit 1
    fi
}

# Enable WAL archiving
EnableWALArchiving ()
{
    if [ ${PGMAJOR} -ge 83 ]; then
	RemoveLineFromFile "^archive_mode" ${PGCONF}
	echo "archive_mode = on" >> ${PGCONF}
    fi

    RemoveLineFromFile "^archive_command" ${PGCONF}
    echo "archive_command = 'cp %p ${PGARCH}/%f'" >> ${PGCONF}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
ParseHelpOption ${@}
GetPgData ${@}
ValidatePgData

# WAL archiving must be supported in this pgsql version
WALArchivingIsSupported

# Create new archive directory
rm -rf ${PGARCH}
mkdir ${PGARCH}

# Enable WAL archiving
EnableWALArchiving
