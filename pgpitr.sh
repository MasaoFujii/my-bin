#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
	UsageForHelpOption "prepares for an archive recovery"
}

# Prepare for an archive recovery
PrepareForArchiveRecovery ()
{
	# Replace the old $PGDATA with a base backup
	rm -rf ${PGDATA}
	cp -r ${PGDATABKP} ${PGDATA}

	# Replace the old archive directory with a backup if it exists
	if [ -d ${PGARCHBKP} ]; then
		rm -rf ${PGARCH}
		cp -r ${PGARCHBKP} ${PGARCH}
	fi

	# Create recovery.conf and specify restore_command
	RESTORECMD="cp ../${PGARCHNAME}/%f %p"
    echo "restore_command = '${RESTORECMD}'" > ${RECOVERYCONF}
}

# Check that we are in the pgsql installation directory
CurDirIsPgsqlIns

# Parse command-line arguments
ParsingForHelpOption ${@}
GetPgData ${@}
ValidatePgData

# Prepare for an archive recovery if pgsql is NOT running
PgsqlMustNotRunning
PrepareForArchiveRecovery
