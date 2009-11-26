#!/bin/sh

# Load the common functions and variables
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
    echo "${PROGNAME} compiles pgsql"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] PREFIX"
    echo ""
    echo "Default:"
    echo "  configure --prefix=PREFIX && make install"
    echo ""
    echo "Options:"
    echo "  -a           enables all options for debug (= -c -d -o)"
    echo "  -c           uses \"--enable-cassert\" option"
    echo "  -d           uses \"--enable-debug\" option"
    echo "  -f FLAGS     uses FLAGS as CPPFLAGS"
    echo "  -h           shows this help, then exits"
    echo "  -l FILENAME  writes compilation log to FILENAME"
    echo "  -z           prevents compiler's optimization"
}

# Get the path of PREFIX from the first command-line argument
# NOTE: "${@}" should be passed as an argument.
GetPrefix ()
{
    if [ ${#} -lt 1 ]; then
	echo "ERROR: PREFIX must be supplied"
	echo ""
	Usage
	exit 1
    fi

    PREFIX=${1}
}

# Validate PREFIX
ValidatePrefix ()
{
    # Parent directory of PREFIX must exist
    PARENTDIR=$(dirname ${PREFIX})
    if [ ! -d ${PARENTDIR} ]; then
	echo "ERROR: Invalid PREFIX; parent directory of PREFIX must exist"
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

# Should be in pgsql source directory
CurDirIsPgsqlSrc

# Parse options
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
    esac
done
shift $(expr ${OPTIND} - 1)

# Get and validate PREFIX
GetPrefix ${@}
ValidatePrefix

# Compile pgsql!
CompilePgsql > ${LOGFILE} 2>&1
