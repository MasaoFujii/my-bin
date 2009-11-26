#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
	UsageForHelpOption "starts pgsql"
}

# Check that we are in the pgsql installation directory
CurDirIsPgsqlIns

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Start pgsql if it's NOT running
PgsqlMustNotRunning "pgsql is already running; no need to start pgsql again"
${PGBIN}/pg_ctl -D ${PGDATA} start
