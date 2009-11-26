#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
	UsageForHelpOption "opens pg_hba.conf with emacs"
}

# Check that we are in the pgsql installation directory
CurDirIsPgsqlIns

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Open pg_hba.conf
emacs ${PGHBA} &
