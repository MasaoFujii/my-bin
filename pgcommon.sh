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

elog ()
{
	echo "$PROGNAME:  ERROR: $1" 1>&2
	exit 1
}

here_is_source ()
{
	if [ ! -f $CURDIR/configure ]; then
		elog "here is NOT source directory: \"$CURDIR\""
	fi
}

here_is_installation ()
{
	if [ ! -f $PGBIN/pg_config ]; then
		elog "here is NOT installation directory: \"$CURDIR\""
	fi

	PGMAJOR=$($PGBIN/pg_config --version | tr -d [A-z' '] | cut -d. -f1-2 | tr -d .)
}

pgdata_exists ()
{
	if [ ! -d $PGDATA ]; then
		elog "database cluster \"$PGDATA\" is NOT found"
	fi
}

archiving_is_supported ()
{
	if [ $PGMAJOR -lt 80 ]; then
		elog "WAL archiving is NOT supported in $($PGBIN/pg_config --version)"
	fi
}

pgsql_is_alive ()
{
	_PGDATA="$PGDATA"
	if [ ! -z "$1" ]; then
		_PGDATA="$1"
	fi
	$PGBIN/pg_ctl -D $_PGDATA status > /dev/null
	if [ $? -ne 0 ]; then
		elog "PostgreSQL server is NOT running; You have to start it right now."
	fi
}

pgsql_is_dead ()
{
	_PGDATA="$PGDATA"
	if [ ! -z "$1" ]; then
		_PGDATA="$1"
	fi
	$PGBIN/pg_ctl -D $_PGDATA status > /dev/null
	if [ $? -eq 0 ]; then
		elog "PostgreSQL server is still running; You have to shut down it right now."
	fi
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
