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

	PGMAJOR=$($PGBIN/pg_config --version | tr --delete [A-z' '] | cut -d. -f1-2 | tr --delete .)
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
	$PGBIN/pg_ctl -D $PGDATA status > /dev/null
	if [ $? -ne 0 ]; then
		elog "postgres server must be dead; you have to start it at first"
	fi
}

pgsql_is_dead ()
{
	$PGBIN/pg_ctl -D $PGDATA status > /dev/null
	if [ $? -eq 0 ]; then
		elog "postgres server must be alive; you have to shut down it at first"
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
