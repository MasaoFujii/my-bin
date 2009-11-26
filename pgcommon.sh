#!/bin/sh

# Common global variables
CURDIR=$(pwd)
PROGNAME=$(basename ${0})

# Directories of pgsql
PGBIN=${CURDIR}/bin
PGDATA=${CURDIR}/data

# Current location is pgsql source dir?
CurDirIsPgsqlSrc ()
{
    if [ ! -f ${CURDIR}/configure ]; then
	echo "ERROR: invalid current location; move to pgsql source directory"
	exit 1
    fi
}

# Current location is pgsql installation dir?
CurDirIsPgsqlIns ()
{
    if [ ! -f ${PGBIN}/pg_config ]; then
	echo "ERROR: invalid current location; move to pgsql installation directory"
	exit 1
    fi
}
