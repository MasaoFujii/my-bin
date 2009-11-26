#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
    echo "${PROGNAME} creates etags files"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Should be in pgsql source directory
CurDirIsPgsqlSrc

# Parse options
ParseHelpOption ${@}

# Create etags files
${CURDIR}/src/tools/make_etags
