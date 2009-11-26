#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
    echo "${PROGNAME} creates \"etags\" files"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [-h]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Check that we are in the pgsql source directory
CurDirIsPgsqlSrc

# Parse command-line arguments
ParsingForHelpOption ${@}

# Create etags files
${CURDIR}/src/tools/make_etags
