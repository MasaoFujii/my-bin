#!/bin/sh

# Load common definitions
. pgcommon.sh

# Show usage
Usage ()
{
    echo "${PROGNAME} creates an initial database cluster"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

# Parse options
ParseHelpOption ${@}
GetPgData ${@}

# Delete old $PGDATA after checking pgsql is not in progress
PgsqlMustNotRunning
rm -rf ${PGDATA}

# Create initial database cluster
${PGBIN}/initdb -D ${PGDATA} --no-locale --encoding=UTF8
echo "host all all 0.0.0.0/0 trust" >> ${PGDATA}/pg_hba.conf
echo "listen_addresses = '*'"       >> ${PGDATA}/postgresql.conf
echo "checkpoint_segments = 64"     >> ${PGDATA}/postgresql.conf
