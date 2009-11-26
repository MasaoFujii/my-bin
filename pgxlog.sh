#!/bin/sh

# Load common definitions
. pgcommon.sh

# Local variables
LIST_PGXLOG="FALSE"
LIST_PGARCH="FALSE"
LIST_PGARCHSTATUS="FALSE"
LIST_INTERVAL=
LIST_ARGS=
LIST_OPTS=

# Show usage
Usage ()
{
    echo "${PROGNAME} lists WAL files"
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS] [PGDATA]"
    echo ""
    echo "Default:"
    echo "  lists online WAL files once"
    echo ""
    echo "Options:"
    echo "  -a        lists archived WAL files"
    echo "  -h        shows this help, then exits"
    echo "  -l        uses a long listing format"
    echo "  -n SECS   interval; lists every SECS"
    echo "  -s        lists archive_status files"
    echo "  -x        lists online WAL files"
}

# List online WAL files
ListPgXlog ()
{
    # List online WAL files by default if no option specified
    if [ "${LIST_PGXLOG}" = "FALSE" -a "${LIST_PGARCH}" = "FALSE" -a "${LIST_PGARCHSTATUS}" = "FALSE" ]; then
	LIST_PGXLOG="TRUE"
    fi

    if [ "${LIST_PGXLOG}" = "TRUE" ]; then
	echo ${PGXLOG}
	ls ${LIST_OPTS} ${PGXLOG}
	echo ""
    fi
}

# List archived WAL files
ListPgArch ()
{
    if [ "${LIST_PGARCH}" = "TRUE" ]; then
	echo ${PGARCH}
	ls ${LIST_OPTS} ${PGARCH}
	echo ""
    fi
}

# List archive_status files
ListPgArchStatus ()
{
    if [ "${LIST_PGARCHSTATUS}" = "TRUE" ]; then
	echo ${PGARCHSTATUS}
	ls ${LIST_OPTS} ${PGARCHSTATUS}
	echo ""
    fi
}

# Check that archive directory exists if it's listed
CanListPgArch ()
{
    if [ "${LIST_PGARCH}" = "TRUE" -a ! -d ${PGARCH} ]; then
	echo "ERROR: archive directory must exist; ${PGARCH}"
	exit 1
    fi
}

# Should be in pgsql installation directory
CurDirIsPgsqlIns

while getopts "ahln:sx" OPT; do
    case ${OPT} in
	a)
	    LIST_PGARCH="TRUE"
	    LIST_ARGS="-a ${LIST_ARGS}"
	    ;;
	h)
	    Usage
	    exit 0
	    ;;
	l)
	    LIST_OPTS="-l ${LIST_OPTS}"
	    LIST_ARGS="-l ${LIST_ARGS}"
	    ;;
	n)
	    LIST_INTERVAL=${OPTARG}
	    ;;
	s)
	    LIST_PGARCHSTATUS="TRUE"
	    LIST_ARGS="-s ${LIST_ARGS}"
	    ;;
	x)
	    LIST_PGXLOG="TRUE"
	    LIST_ARGS="-x ${LIST_ARGS}"
	    ;;
    esac
done
shift $(expr ${OPTIND} - 1)

# Get and validate $PGDATA
GetPgData ${@}
ValidatePgData

# Can archive directory be listed if required
CanListPgArch

# List WAL files
if [ -z "${LIST_INTERVAL}" ]; then
    ListPgXlog
    ListPgArchStatus
    ListPgArch
else
    watch -n${LIST_INTERVAL} "pgxlog.sh ${LIST_ARGS}"
fi
