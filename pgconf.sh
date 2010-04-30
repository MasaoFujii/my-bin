#!/bin/sh

# Load common definitions
. pgcommon.sh

# Local functions
Usage ()
{
	UsageForHelpOption "opens postgresql.conf with emacs"
}

here_is_installation

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Open postgresql.conf
emacs ${PGCONF} &
