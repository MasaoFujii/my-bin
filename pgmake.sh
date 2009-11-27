#!/bin/sh

# Load common definitions
. pgcommon.sh

# Compile variables
ENABLE_CASSERT="FALSE"
ENABLE_DEBUG="FALSE"
ENABLE_OPTIMIZATION="TRUE"
LOGFILE=/tmp/pgmake.log
PREFIX=
CONFIGURE_OPTS=

# Show usage
Usage ()
{
    echo "${PROGNAME} compiles and installs pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] PREFIX"
    echo ""
    echo "Default:"
    echo "  runs \"configure --prefix=PREFIX\" and \"make install\""
    echo ""
    echo "Options:"
    echo "  -a           enables all options for debug (i.e., -c -d -z)"
    echo "  -c           uses \"--enable-cassert\" option"
    echo "  -d           uses \"--enable-debug\" option"
    echo "  -f FLAGS     uses FLAGS as CPPFLAGS"
    echo "  -h           shows this help, then exits"
    echo "  -l FILEPATH  writes compilation log to FILEPATH"
    echo "  -z           prevents compiler's optimization"
}

# Get PREFIX from command-line arguments, and validate it.
#
# Arguments:
#   [1]: command-line argument; "${@}" must be supplied.
GetAndValidatePrefix ()
{
    # Check that one argument is supplied
    if [ ${#} -lt 1 ]; then
	echo "ERROR: PREFIX must be supplied"
	echo ""
	Usage
	exit 1
    fi
    PREFIX=${1}

    # Check that parent directory of PREFIX exists
    PARENTDIR=$(dirname ${PREFIX})
    if [ ! -d ${PARENTDIR} ]; then
	echo "ERROR: invalid PREFIX; its parent directory is not found"
	exit 1
    fi
}

# Construct configure's options
ConstructConfigureOpts ()
{
    if [ "${ENABLE_CASSERT}" = "TRUE" ]; then
	CONFIGURE_OPTS="--enable-cassert"
    fi

    if [ "${ENABLE_DEBUG}" = "TRUE" ]; then
	CONFIGURE_OPTS="--enable-debug ${CONFIGURE_OPTS}"
    fi
}

# Prevent compiler's optimization
PreventOptimization ()
{
    if [ "${ENABLE_OPTIMIZATION}" = "TRUE" ]; then
	return
    fi

    GLOBALMAKEFILE=${CURDIR}/src/Makefile.global
    sed s/\-O2//g ${GLOBALMAKEFILE} > ${TMPFILE}
    mv ${TMPFILE} ${GLOBALMAKEFILE}
}

# Compile pgsql!
CompilePgsql ()
{
    # Clean up
    pgclean.sh -m

    # Configure
    ConstructConfigureOpts
    ./configure --prefix=${PREFIX} ${CONFIGURE_OPTS}

    # Prevent optimization
    PreventOptimization

    # Compile and install pgsql
    make install

    # Compile and install contrib modules
    CONTRIBDIR=${CURDIR}/contrib
    PGBENCHDIR=${CONTRIBDIR}/pgbench
    PGSTANDBYDIR=${CONTRIBDIR}/pg_standby
    cd ${PGBENCHDIR}
    make install
    cd ${PGSTANDBYDIR}
    make install
    cd ${CURDIR}
}

# Check that we are in the pgsql source directory
CurDirIsPgsqlSrc

# Determine the compilation options
while getopts "acdf:hl:z" OPT; do
    case ${OPT} in
	a)
	    ENABLE_CASSERT="TRUE"
	    ENABLE_DEBUG="TRUE"
	    ENABLE_OPTIMIZATION="FALSE"
	    ;;
	c)
	    ENABLE_CASSERT="TRUE"
	    ;;
	d)
	    ENABLE_DEBUG="TRUE"
	    ;;
	f)
	    export CPPFLAGS="${OPTARG} ${CPPFLAGS}"
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
	l)
	    LOGFILE="${OPTARG}"
	    ;;
	z)
	    ENABLE_OPTIMIZATION="FALSE"
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

# Get and validate PREFIX
GetAndValidatePrefix ${@}

# Compile pgsql!
CompilePgsql > ${LOGFILE} 2>&1
