#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local variables
TARGETFILES="[chy]"
KEYWORD=

# Show usage
Usage ()
{
    echo "${PROGNAME} extracts the line including KEYWORD from pgsql src"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] KEYWORD"
    echo ""
    echo "Default:"
    echo "  extracts a line from *.[chy] files"
    echo ""
    echo "Options:"
    echo "  -c        extracts a line from *.[chy] files"
    echo "  -d        extracts a line from *.sgml files"
    echo "  -h        shows this help, then exits"
}

# Get KEYWORD from the first command-line argument.
# NOTE: "${@}" should be passed as an argument.
GetKeyword ()
{
    if [ ${#} -lt 1 ]; then
	echo "ERROR: KEYWORD must be supplied"
	echo ""
	Usage
	exit 1
    fi

    KEYWORD=${1}
}

# Should be in pgsql source directory
CurDirIsPgsqlSrc

# Parse options
while getopts "cdh" OPT; do
    case ${OPT} in
	c)
	    TARGETFILES="[chy]"
	    ;;
	d)
	    TARGETFILES="sgml"
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
    esac
done
shift $(expr ${OPTIND} - 1)

# Get KEYWORD
GetKeyword ${@}

# Extract the line including KEYWORD
for TARGETFILE in $(find ${CURDIR} -name "*.${TARGETFILES}"); do
    grep -H "${KEYWORD}" ${TARGETFILE}
done
