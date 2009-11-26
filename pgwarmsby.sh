#!/bin/sh

# Load the common functions and variables
. pgcommon.sh

# Local variables
PGSTANDBY=${PGBIN}/pg_standby
ACTDATA=${CURDIR}/act
ACTCONF=${ACTDATA}/postgresql.conf
ACTPORT=5432
SBYDATA=${CURDIR}/sby
SBYCONF=${SBYDATA}/postgresql.conf
SBYPORT=5433
PGARCH=${CURDIR}/arch
TRIGGER=${CURDIR}/trigger
RECOVERYCONF=${SBYDATA}/recovery.conf

# Show usage
Usage ()
{
    echo "${PROGNAME} configures warm-standby"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# pg_standby is installed?
MustHavePgStandby ()
{
    if [ ${PGMAJOR} -lt 82 ]; then
	echo "ERROR: warm-standby is not supported"
	exit 1
    fi

    if [ ! -f ${PGSTANDBY} ]; then
	echo "ERROR: pg_standby must be installed"
	exit 1
    fi
}

# Configure for act
ConfigAct ()
{
    SetOneGuc port ${ACTPORT} ${ACTCONF}
    SetOneGuc log_line_prefix "'ACT '" ${ACTCONF}
}

# Configure for sby
ConfigSby ()
{
    SetOneGuc port ${SBYPORT} ${SBYCONF}
    SetOneGuc log_line_prefix "'SBY '" ${SBYCONF}

    # Set up pg_standby
    echo "${PGSTANDBY} -t ${TRIGGER} ${PGARCH} %f %p" > ${RECOVERYCONF}
}

# Setup warm-standby
SetupWarmStandby ()
{
    pginitdb.sh ${ACTDATA}
    pgarch.sh -A ${PGARCH} ${ACTDATA}
    ConfigAct
    pgstart.sh ${ACTDATA}
    WaitForNormalPgsql
    pgbackup.sh -D ${SBYDATA} ${ACTDATA}
    ConfigSby
    pgstart.sh ${SBYDATA}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Can we configure warm-standby?
ArchivingIsSupported
MustHavePgStandby

# Parse options
ParseHelpOption ${@}

# Delete old objects
rm -rf ${ACTDATA} ${SBYDATA} ${PGARCH} ${TRIGGER}

# Set up warm-standby
SetupWarmStandby