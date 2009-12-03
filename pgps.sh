#!/bin/sh

## Variables
PROGNAME=${0}

## Options by command-line arguments
PGPS_BATCH=FALSE
PGPS_DELAY=1
PGPS_1TIME=FALSE

## Usage
usage ()
{
    echo "${PROGNAME} provides a dynamic real-time view of running postgres processes."
    echo "By default, screen is updated every 1 second."
    echo ""
    echo "Usage:"
    echo "  ${PROGNAME} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b            Starts ${PROGNAME} in 'Batch mode', which could be useful for"
    echo "                sending output from ${PROGNAME} to other programs or to a file."
    echo "  -d SECONDS    Specifies the delay between screen updates."
    echo "  -1            Starts ${PROGNAME} in '1-time mode', which reports a snapshot only once"
}

## Parse command-line arguments
while getopts "bd:1" OPT
  do
  case ${OPT} in
      b)
	  PGPS_BATCH=TRUE
	  ;;
      d)
	  PGPS_DELAY=${OPTARG}
	  ;;
      1)
	  PGPS_1TIME=TRUE
	  ;;
  esac
done

## Report a snapshot of the current postgres processes
pgps_report_snapshot ()
{
    date

    PGPS_PIDLIST=$(pgrep -d, -x postgres)
    if [ "${PGPS_PIDLIST}" != "" ]; then
	ps -fp ${PGPS_PIDLIST}
	echo ""
    fi
}

## Main
### 1-time mode
if [ "${PGPS_1TIME}" == "TRUE" ]; then
    pgps_report_snapshot
    exit 0
fi

### Batch mode
if [ "${PGPS_BATCH}" == "TRUE" ]; then
    while [ 1 ]
      do
      pgps_report_snapshot
      sleep ${PGPS_DELAY}
    done

### Real-time view mode
else
    watch -n${PGPS_DELAY} "${PROGNAME} -1"
fi
