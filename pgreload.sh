#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local functions
Usage ()
{
    echo "${PROGNAME} reloads pgsql configuration files"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
ParseHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Reload pgsql conf files after checking it's in progress
PgsqlMustRunning
${PGBIN}/pg_ctl -D ${PGDATA} reload
