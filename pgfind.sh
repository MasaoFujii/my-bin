#!/bin/sh

# Load common definitions
. pgcommon.sh

# Local variables
TARGET_EXTENSION="[chy]"
KEYWORD=

# Show usage
Usage ()
{
    echo "${PROGNAME} extracts the line including KEYWORD from pgsql files"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] KEYWORD"
    echo ""
    echo "Default:"
    echo "  extracts from source code files"
    echo ""
    echo "Options:"
    echo "  -c        extracts from source code files"
    echo "  -d        extracts from document files"
    echo "  -h        shows this help, then exits"
}

# Get KEYWORD from command-line arguments.
#
# Arguments:
#   [1]: command-line argument; "${@}" must be supplied.
GetKeyword ()
{
    # Check that one argument is supplied
    if [ ${#} -lt 1 ]; then
	echo "ERROR: KEYWORD must be supplied"
	echo ""
	Usage
	exit 1
    fi
    KEYWORD="${1}"
}

# Check that we are in the pgsql source directory
CurDirIsPgsqlSrc

# Determine the search target files
while getopts "cdh" OPT; do
    case ${OPT} in
	c)
	    TARGET_EXTENSION="[chy]"
	    ;;
	d)
	    TARGET_EXTENSION="sgml"
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
    esac
done
shift $(expr ${OPTIND} - 1)

# Get KEYWORD
GetKeyword "${@}"

# Extract the line including KEYWORD
for TARGETFILE in $(find ${CURDIR} -name "*.${TARGET_EXTENSION}"); do
    grep -H "${KEYWORD}" ${TARGETFILE}
done
