#!/bin/sh

CURDIR=$(pwd)
PROGNAME=$(basename ${0})

usage ()
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

if [ ! -f ${CURDIR}/configure ]; then
    echo "ERROR: invalid present location"
    echo "HINT : you need to move to pgsql source directory"
    exit 1
fi

ALL_CLEAN="FALSE"
MAINTAINER_CLEAN="FALSE"
while getopts "ahm" OPT; do
    case ${OPT} in
	a)
	    ALL_CLEAN="TRUE"
	    MAINTAINER_CLEAN="TRUE"
	    ;;
	h)
	    usage
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
