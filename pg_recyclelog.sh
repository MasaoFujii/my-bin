#!/bin/sh

# Exit immediately if a command exits with non-zero status
set -e

#### Definition of global variables ####

# The name of this program
PROGNAME=$(basename ${0})

# Path to PostgreSQL database cluster directory
#
# When this command is executed via recovery_end_command,
# the path must be current working directory (i.e., .)
PGDATA=.

# Path to pg_xlog directory
PGXLOG=$PGDATA/pg_xlog

# Path to PostgreSQL executable directory
PGBIN=

# Path to pg_controldata command
PGCTLDATA=pg_controldata

# Current timeline ID in hex format
CURTLI=

# 8 digits current timeline ID with 0 padding
CURTLI8DIGITS=

# Last used WAL file of immediate parent timeline
OLDTLIWAL=

# Size of a single WAL file in hex format
XLOG_SEG_SIZE=


#### Definition of functions ####

# Convert the specified decimal number to a hex format
dec2hex ()
{
	printf "%X\n" "$1"
}

# Calculate WAL file name containing the specified LSN
lsn2walfile ()
{
	LSN="$1"

	# Compute logid and segid from LSN
	LOGID=$(echo "$LSN" | cut -d/ -f1)
	XRECOFF=$(echo "$LSN" | cut -d/ -f2)
	SEGID=$(echo "obase=16; ibase=16; (${XRECOFF}-1)/${XLOG_SEG_SIZE}" | bc)

	# Construct WAL file name
	printf "%s%08X%08X\n" $CURTLI8DIGITS 0x$LOGID 0x$SEGID
}

# Make the specified path canonical
make_path_canonical ()
{
	DIRNAME=$(dirname "$1")
	FILENAME=$(basename "$1")
	echo "$DIRNAME/$FILENAME"
}

# Get the value of the specified keyword from the result of pg_control
get_pg_control_value ()
{
	KEY="$1"
	RESULT="$2"

	echo "$RESULT" | grep "$KEY" | cut -d: -f2 | sed s/"^ "*//g
}

# Read pg_control file
read_pg_control ()
{
	# Force the output of pg_controldata English to 'grep' the specified line
	LANG=C

	# Read pg_control
	RESULT=$($PGCTLDATA $PGDATA)

	# Check whether the current database cluster state is valid (i.e., "shut down")
	#
	# The recovery end checkpoint must be completed just before executing
	# this command via recovery_end_command.
	DBSTATE=$(get_pg_control_value "Database cluster state:" "$RESULT")
	if [ "$DBSTATE" != "shut down" ]; then
		elog "invalid database cluster state: $DBSTATE"
	fi

	# Get the size of a single WAL file in hex format
	XLOG_SEG_SIZE=$(get_pg_control_value "Bytes per WAL segment:" "$RESULT")
	XLOG_SEG_SIZE=$(dec2hex "$XLOG_SEG_SIZE")

	# Get the current timeline ID in hex format
	CURTLI=$(get_pg_control_value "Latest checkpoint's TimeLineID:" "$RESULT")
	CURTLI=$(dec2hex "$CURTLI")
	CURTLI8DIGITS=$(printf "%08X\n" 0x$CURTLI)
}

# Read current timeline history file
read_current_timeline_history ()
{
	# Check whether current timeline history file exists in pg_xlog directory
	TLIHST=$PGXLOG/${CURTLI8DIGITS}.history
	if [ ! -f "$TLIHST" ]; then
		elog "current timeline history file \"${TLIHST}\" does not exist"
	fi

	# Read the tailing line of current timeline history file, which contains the last
	# used WAL file name of immediate parent timeline
	OLDTLIWAL=$(tail -1 $TLIHST | cut -f2)
}

# Return 0 if the first string is less than the second in alphabetical order
strcmp_le ()
{
	STR1="$1"
	STR2="$2"

	LESSTHAN=$(printf "%s\n%s" $STR1 $STR2 | sort -d | head -1)
	if [ "$LESSTHAN" = "$STR1" ]; then
		return 0
	else
		return 1
	fi
}

# Recycle or remove all WAL files newer than last used WAL file of
# immediate parent timeline, except WAL files of current timeline
recycle_unused_walfiles ()
{
	LASTLOGSEG=$(echo "$OLDTLIWAL" | cut -c9-24)

	# Ignore WAL files of current timeline
	for walfile in $(ls $PGXLOG | grep -v -E "^$CURTLI8DIGITS"); do

		# Ignore files other than WAL file
		if [ ${#walfile} -ne 24 ]; then
			continue
		fi

		# Ignore WAL files whose log and seg are older than or equal to
		# those of OLDTLIWAL
		THISLOGSEG=$(echo "$walfile" | cut -c9-24)
		if [ strcmp_le "$THISLOGSEG" "$LASTLOGSEG" ]; then
			continue
		fi
	done
}

# Emit the specified log message to stderr and exit with non-zero status
elog ()
{
	echo "$PROGNAME: $1" 1>&2
	exit 1
}

# Show the help message
usage ()
{
	echo "$PROGNAME recycles unusable WAL files with old timeline."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --pgbin=PATH    path to postgres executable directory"
}


#### Main ####

# Parse the command-line arguments
while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		--pgbin)
			PGBIN=$(make_path_canonical "$2")
			shift;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

# Determine the path to PostgreSQL commands
if [ ! -z "$PGBIN" ]; then
	PGCTLDATA="$PGBIN/$PGCTLDATA"
fi

# Read pg_control file and get the information of current database cluster
read_pg_control

# Read current timeline history file and get the last used WAL file of old timeline
read_current_timeline_history
