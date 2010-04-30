#!/bin/sh

# Load common definitions
. pgcommon.sh

# Cleaning modes
CLEAN_ALL="FALSE"
CLEAN_MAINTAINER="FALSE"

# Show usage
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

here_is_source

# Determines the cleaning mode
while getopts "ahm" OPT; do
    case ${OPT} in
	a)
	    CLEAN_ALL="TRUE"
	    CLEAN_MAINTAINER="TRUE"
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
	m)
	    CLEAN_MAINTAINER="TRUE"
	    ;;
	*)
	    echo "ERROR: invalid option; \"${OPT}\""
	    echo ""
	    Usage
	    exit 1
	    ;;
    esac
done
shift $(expr ${OPTIND} - 1)

# Perform cleanup
if [ "${CLEAN_MAINTAINER}" = "TRUE" ]; then
    make maintainer-clean
else
    make clean
fi

if [ "${CLEAN_ALL}" = "TRUE" ]; then
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
