#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
    echo "${PROGNAME} prepares archive recovery"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Prepare archive recovery
PrepareArchiveRecovery ()
{
    # Set up new $PGDATA
    rm -rf ${PGDATA}
    cp -r ${PGDATABKP} ${PGDATA}

    # Set up new $PGARCH
    if [ -d ${PGARCHBKP} ]; then
	rm -rf ${PGARCH}
	cp -r ${PGARCHBKP} ${PGARCH}
    fi

    # Supply restore_command
    echo "restore_command = 'cp ../${PGARCHNAME}/%f %p'" > ${RECOVERYCONF}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
ParseHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Prepare archive recovery after checking pgsql isn't in progress
PgsqlMustNotRunning
PrepareArchiveRecovery
