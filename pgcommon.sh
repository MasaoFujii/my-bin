#!/bin/sh

CURDIR=$(pwd)
PROGNAME=$(basename ${0})
TMPFILE=/tmp/pgscript_$(date +%Y%m%d%H%M%S).tmp
PGMAJOR=

PGBIN=$CURDIR/bin
PGDATA=
PGARCH=
PGXLOG=
PGARCHSTATUS=
PGDATABKP=
PGARCHBKP=
PGCONF=
PGHBA=
RECOVERYCONF=

update_pgdata ()
{
	PGDATA="$1"
	PGARCH=$PGDATA.arh
	PGXLOG=$PGDATA/pg_xlog
	PGARCHSTATUS=$PGXLOG/archive_status
	PGDATABKP=$PGDATA.bkp
	PGARCHBKP=$PGARCH.bkp
	PGCONF=$PGDATA/postgresql.conf
	PGHBA=$PGDATA/pg_hba.conf
	RECOVERYCONF=$PGDATA/recovery.conf
}
update_pgdata "$CURDIR/data"

here_is_source ()
{
	if [ ! -f $CURDIR/configure ]; then
		echo "$PROGNAME: here is NOT source directory: \"$CURDIR\"" 2>&1
		exit 1
	fi
}

here_is_installation ()
{
	if [ ! -f $PGBIN/pg_config ]; then
		echo "$PROGNAME: here is NOT installation directory: \"$CURDIR\"" 2>&1
		exit 1
	fi

	PGMAJOR=$($PGBIN/pg_config --version | tr --delete [A-z' '] | cut -d. -f1-2 | tr --delete .)
}

check_directory_exists ()
{
	if [ ! -d "$1" ]; then
		echo "$PROGNAME: %2 is NOT found: \"$1\""
		exit 1
	fi
}

archiving_is_supported ()
{
	if [ $PGMAJOR -lt 80 ]; then
		echo "$PROGNAME: WAL archiving is NOT supported in $($PGBIN/pg_config --version)" 2>&1
		exit 1
	fi
}

# Get the path of $PGDATA from the first commad-line argument.
# NOTE: "${@}" should be passed as an argument.
GetPgData ()
{
    if [ ${#} -gt 0 ]; then
	PGDATA=${1}
    fi

    # The following paths are derived from $PGDATA
    PGARCH=${PGDATA}.arh
    PGXLOG=${PGDATA}/pg_xlog
    PGARCHSTATUS=${PGXLOG}/archive_status
    PGDATABKP=${PGDATA}.bkp
    PGARCHBKP=${PGARCH}.bkp
    PGCONF=${PGDATA}/postgresql.conf
    PGHBA=${PGDATA}/pg_hba.conf
    RECOVERYCONF=${PGDATA}/recovery.conf
}

# Validate that $PGDATA is found.
ValidatePgData ()
{
    if [ ! -d ${PGDATA} ]; then
	echo "ERROR: \$PGDATA is not found: ${PGDATA}"
	exit 1
    fi
}

# Emit an error if pgsql is NOT running.
#
# Arguments:
#   [1]: error message (optional)
PgsqlMustRunning ()
{
	# Determine error message
	ERRORMSG="pgsql is NOT running; start up pgsql right now!"
	if [ ${#} -ge 1 ]; then
		ERRORMSG=${1}
	fi

	# Check if pgsql is running
	${PGBIN}/pg_ctl -D ${PGDATA} status > /dev/null
	if [ ${?} -ne 0 ]; then
		echo "ERROR: ${ERRORMSG}"
		exit 1
	fi
}

# Emit an error if pgsql IS running.
#
# Arguments:
#   [1]: error message (optional)
PgsqlMustNotRunning ()
{
	# Determine error message
	ERRORMSG="pgsql is still running; shut down pgsql right now!"
	if [ ${#} -ge 1 ]; then
		ERRORMSG=${1}
	fi

	# Check if pgsql is running
	${PGBIN}/pg_ctl -D ${PGDATA} status > /dev/null
	if [ ${?} -eq 0 ]; then
		echo "ERROR: ${ERRORMSG}"
		exit 1
	fi
}

# Show very simple usage which handles only help (-h) option.
#
# Arguments:
#   [1]: outline of the script
UsageForHelpOption ()
{
	# Check that one argument is supplied.
	if [ ${#} -lt 1 ]; then
		echo "ERROR: too few arguments in UsageForHelpOption"
		exit 1
	fi
	OUTLINE=${1}

	# Show simple usage
	echo "${PROGNAME} ${OUTLINE}"
	echo ""
	echo "Usage:"
	echo "  ${PROGNAME} [-h] [PGDATA]"
	echo ""
	echo "Options:"
    echo "  -h        shows this help, then exits"
}

# Parse command-line arguments which is expected to
# include only help (-h) option.
#
# Arguments:
#   [1]: command-line argument; "${@}" must be supplied.
#
# Note:
#   The function "Usage" must be called before this.
ParsingForHelpOption ()
{
	while getopts "h" OPT; do
		case ${OPT} in
			h)
				Usage
				exit 0
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
}

remove_line ()
{
	PATTERN="$1"
	TARGETFILE="$2"

	sed /"$PATTERN"/D $TARGETFILE > $TMPFILE
	mv $TMPFILE $TARGETFILE
}

set_guc ()
{
	GUCNAME="$1"
	GUCVALUE="$2"
	CONFPATH="$3"

	remove_line "^$GUCNAME" $CONFPATH
	echo "$GUCNAME = $GUCVALUE" >> $CONFPATH
}

elog ()
{
	echo "$PROGNAME: ERROR: $1" 1>&2
	exit 1
}