#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local functions
Usage ()
{
    echo "${PROGNAME} deletes the useless files"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Default:"
    echo "  runs just \"make clean\""
    echo ""
    echo "Options:"
    echo "  -a        runs \"make maintainer-clean\" and deletes all the useless files"
    echo "  -h        shows this help, then exits"
    echo "  -m        runs \"make maintainer-clean\""
}

# Should be in pgsql source directory
CurDirIsPgsqlSrc

ALL_CLEAN="FALSE"
MAINTAINER_CLEAN="FALSE"
while getopts "ahm" OPT; do
    case ${OPT} in
	a)
	    ALL_CLEAN="TRUE"
	    MAINTAINER_CLEAN="TRUE"
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
	m)
	    MAINTAINER_CLEAN="TRUE"
	    ;;
    esac
done

if [ "${MAINTAINER_CLEAN}" = "TRUE" ]; then
    make maintainer-clean
else
    make clean
fi

if [ "${ALL_CLEAN}" = "TRUE" ]; then
    for garbage in $(find . -name "TAGS"); do
	rm -f ${garbage}
    done

    for garbage in $(find . -name "*~"); do
	rm -f ${garbage}
    done

    for garbage in $(find . -name "*.orig"); do
	rm -f ${garbage}
    done

    for garbage in $(find . -name "*.rej"); do
	rm -f ${garbage}
    done
fi
