#!/bin/sh

# Load common definitions
. pgcommon.sh

# Check that we are in the pgsql installation directory
CurDirIsPgsqlIns

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Reload pgsql configuration files if pgsql is running
PgsqlMustRunning "pgsql is NOT running; there is no point in reloading configuration files"
${PGBIN}/pg_ctl -D ${PGDATA} reload
