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

# Enable WAL archiving
EnableWALArchiving ()
{
    if [ ${PGMAJOR} -ge 83 ]; then
	RemoveLineFromFile "^archive_mode" ${PGCONF}
	echo "archive_mode = on" >> ${PGCONF}
    fi

    RemoveLineFromFile "^archive_command" ${PGCONF}
    echo "archive_command = 'cp %p ../$(basename ${PGARCH})/%f'" >> ${PGCONF}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
ParseHelpOption ${@}
GetPgData ${@}
ValidatePgData

# WAL archiving must be supported in this pgsql version
ArchivingIsSupported

# Create new archive directory
rm -rf ${PGARCH}
mkdir ${PGARCH}

# Enable WAL archiving
EnableWALArchiving
