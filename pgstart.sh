#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
    echo "${PROGNAME} starts pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
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

# Start pgsql after checking it's not in progress
PgsqlMustNotRunning
${PGBIN}/pg_ctl -D ${PGDATA} start
