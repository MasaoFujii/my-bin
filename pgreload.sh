#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
	UsageForHelpOption "reloads the pgsql configuration files"
}

here_is_installation

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Reload pgsql configuration files if pgsql is running
PgsqlMustRunning "pgsql is NOT running; there is no point in reloading configuration files"
${PGBIN}/pg_ctl -D ${PGDATA} reload
