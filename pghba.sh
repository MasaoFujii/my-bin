#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
	UsageForHelpOption "opens pg_hba.conf with emacs"
}

here_is_installation

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Open pg_hba.conf
emacs ${PGHBA} &
