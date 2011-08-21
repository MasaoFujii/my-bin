#!/bin/sh

. bincommon.sh

PGMAJOR=
PGVERSION=
PGPORT=5432

ACTDATA=act
SBYDATA=sby

SBYMIN=1
SBYMAX=16

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
		elog "here is NOT source directory: \"$CURDIR\""
	fi

	PGVERSION=$($PGBIN/configure --version | head -1)
	PGMAJOR=$(echo $PGVERSION | tr -d [A-z' '] | cut -d. -f1-2 | tr -d .)
}

here_is_installation ()
{
	if [ ! -f $PGBIN/pg_config ]; then
		elog "here is NOT installation directory: \"$CURDIR\""
	fi

	PGVERSION=$($PGBIN/pg_config --version)
	PGMAJOR=$(echo $PGVERSION | tr -d [A-z' '] | cut -d. -f1-2 | tr -d .)
}

pgdata_exists ()
{
	if [ ! -d $PGDATA ]; then
		elog "database cluster \"$PGDATA\" is NOT found"
	fi
}

ValidateArchiving ()
{
	if [ $PGMAJOR -lt 80 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=8.0"
		elog "WAL archiving is NOT supported in $PGVERSION" "$HINT"
	fi
}

ValidateReplication ()
{
	if [ $PGMAJOR -lt 90 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=9.0"
		elog "streaming replication is NOT supported in $PGVERSION" "$HINT"
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
	if [ ! -z "$PGMAJOR" -a $PGMAJOR -ge 91 ]; then
		PGPORT=$(sed -n '4,4p' $_PGDATA/postmaster.pid)
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

set_guc ()
{
	GUCNAME="$1"
	GUCVALUE="$2"
	CONFPATH="$3"

	remove_line "^$GUCNAME" $CONFPATH
	echo "$GUCNAME = $GUCVALUE" >> $CONFPATH
}

find_all_pgdata ()
{
	MUSTHAVE="base global pg_clog pg_xlog"

	for pgdata in $(ls $CURDIR | grep -v -e "\.bkp"); do
		if [ ! -d "$pgdata" ]; then
			continue
		fi

		ISPGDATA="TRUE"
		for subdir in $MUSTHAVE; do
			if [ ! -d "$pgdata/$subdir" ]; then
				ISPGDATA="FALSE"
				break
			fi
		done

		if [ "$ISPGDATA" = "TRUE" ]; then
			echo "$pgdata"
		fi
	done
}
