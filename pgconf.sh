#!/bin/sh

# Load common definitions
. pgcommon.sh

# Local functions
Usage ()
{
	UsageForHelpOption "opens postgresql.conf with emacs"
}

# Check that we are in the pgsql installation directory
CurDirIsPgsqlIns

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Open postgresql.conf
emacs ${PGCONF} &
