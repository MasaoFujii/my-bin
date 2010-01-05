#!/bin/sh

# Load common definitions
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

# Set up the configuration file (postgresql.conf) of the primary
# for warm-standby.
SetupActConfig ()
{
    SetOneGuc port ${ACTPORT} ${ACTCONF}
    SetOneGuc log_line_prefix "'ACT '" ${ACTCONF}
}

# Set up the configuration files (postgresql.conf and recovery.conf)
# of the standby for warm-standby.
SetupSbyConfig ()
{
	SetOneGuc port ${SBYPORT} ${SBYCONF}
	SetOneGuc log_line_prefix "'SBY '" ${SBYCONF}

	# Set up pg_standby
	RESTORECMD="${PGSTANDBY} -t ${TRIGGER} -r 1 ${PGARCH} %f %p"
	echo "restore_command = '${RESTORECMD}'" > ${RECOVERYCONF}
}

# Setup warm-standby
SetupWarmStandby ()
{
    pginitdb.sh ${ACTDATA}
    pgarch.sh -A ${PGARCH} ${ACTDATA}
    SetupActConfig
    pgstart.sh ${ACTDATA}
    WaitForPgsqlStartup
    pgbackup.sh ${ACTDATA}
		cp -r $ACTDATA.bkp $SBYDATA
    SetupSbyConfig
    pgstart.sh ${SBYDATA}
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Can we configure warm-standby?
ArchivingIsSupported
MustHavePgStandby

# Parse command-line arguments
ParsingForHelpOption ${@}

# Delete old objects
rm -rf ${ACTDATA} ${SBYDATA} ${PGARCH} ${TRIGGER}

# Set up warm-standby
SetupWarmStandby