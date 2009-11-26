#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local functions
Usage ()
{
    echo "${PROGNAME} opens pg_hba.conf with emacs"
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
SimpleOptionParser ${@}

# Open pg_hba.conf
emacs ${PGDATA}/pg_hba.conf &
