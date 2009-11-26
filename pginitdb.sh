#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
	UsageForHelpOption "creates an initial database cluster"
}

# Set up minimal settings
SetupMinimalSettings ()
{
	SetOneGuc listen_addresses "'*'" ${PGCONF}
	SetOneGuc checkpoint_segments 64 ${PGCONF}
	echo "host	all	all	0.0.0.0/0	trust" >> ${PGHBA}
}

# Check that we are in the pgsql installation directory
CurDirIsPgsqlIns

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}

# Delete old $PGDATA if pgsql is NOT running
PgsqlMustNotRunning
rm -rf ${PGDATA}

# Create initial database cluster
PGLOCALE=C
PGENCODING=UTF8
${PGBIN}/initdb -D ${PGDATA} --locale=${PGLOCALE} --encoding=${PGENCODING}
SetupMinimalSettings
