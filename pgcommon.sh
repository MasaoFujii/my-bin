#!/bin/sh

. bincommon.sh

PGMAJOR=
PGVERSION=
PGPORT=5432

ACTDATA=data
SBYDATA=sby

SBYMIN=1
SBYMAX=16

PGBIN=$CURDIR/bin
PGDATA=
PGARCH=
PGXLOG=
PGXLOGEXT=
PGARCHSTATUS=
PGSUMMARIES=
PGDATABKP=
PGARCHBKP=
PGCONF=
PGHBA=
RECOVERYCONF=
RECOVERYDONE=
RECOVERYSIGNAL=
STANDBYSIGNAL=

PSQL=

GUCFILENAME=postgresql.conf
HBAFILENAME=pg_hba.conf
RECFILENAME=recovery.conf
RECDONENAME=recovery.done
RECSIGNALNAME=recovery.signal
SBYSIGNALNAME=standby.signal

LOGLINEPREFIX="%t"

update_pgxlog ()
{
	if [ ${PGMAJOR:-0} -lt 100 ]; then
		PGXLOG=$PGDATA/pg_xlog
	else
		PGXLOG=$PGDATA/pg_wal
	fi
	PGARCHSTATUS=$PGXLOG/archive_status
	PGSUMMARIES=$PGXLOG/summaries
}

update_pgdata ()
{
	PGDATA="$1"
	PGARCH=$PGDATA.arch
	update_pgxlog
	PGXLOGEXT=$PGDATA.xlog
	PGDATABKP=$PGDATA.bkp
	PGARCHBKP=$PGARCH.bkp
	PGCONF=$PGDATA/$GUCFILENAME
	PGHBA=$PGDATA/$HBAFILENAME
	RECOVERYCONF=$PGDATA/$RECFILENAME
	RECOVERYDONE=$PGDATA/$RECDONENAME
	RECOVERYSIGNAL=$PGDATA/$RECSIGNALNAME
	STANDBYSIGNAL=$PGDATA/$SBYSIGNALNAME
}
update_pgdata "data"

update_log_line_prefix ()
{
	if [ $PGMAJOR -ge 130 ]; then
		LOGLINEPREFIX="%t [%b]"
	fi
}

here_is_source ()
{
	if [ ! -f $CURDIR/configure ]; then
		elog "here is NOT source directory: \"$CURDIR\""
	fi

	PGVERSION=$($CURDIR/configure --version | head -1)
	pgversion_to_pgmajor
}

here_is_installation ()
{
	if [ ! -f $PGBIN/pg_config ]; then
		elog "here is NOT installation directory: \"$CURDIR\""
	fi

	PGVERSION=$($PGBIN/pg_config --version)
	pgversion_to_pgmajor
	update_pgxlog
	update_log_line_prefix
}

pgversion_to_pgmajor ()
{
	PGVERSION_NUM=$(echo ${PGVERSION} | tr -d [A-z' '])
	VER1=$(echo ${PGVERSION_NUM} | cut -d. -f1)
	VER2=$(echo ${PGVERSION_NUM} | cut -d. -f2)
	if [ $VER1 -lt 10 ]; then
		PGMAJOR="${VER1}${VER2}"
	else
		PGMAJOR="${VER1}0"
	fi
}

pgdata_exists ()
{
	if [ ! -d $PGDATA ]; then
		elog "database cluster \"$PGDATA\" is NOT found"
	fi
}

validate_archiving ()
{
	if [ $PGMAJOR -lt 80 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=8.0"
		elog "WAL archiving is NOT supported in $PGVERSION" "$HINT"
	fi
}

validate_replication ()
{
	if [ $PGMAJOR -lt 90 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=9.0"
		elog "streaming replication is NOT supported in $PGVERSION" "$HINT"
	fi
}

validate_cascade_replication ()
{
	if [ $PGMAJOR -lt 92 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=9.2"
		elog "cascade replication is NOT supported in $PGVERSION" "$HINT"
	fi
}

validate_logical_replication ()
{
	if [ $PGMAJOR -lt 100 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=10"
		elog "logical replication is NOT supported in $PGVERSION" "$HINT"
	fi
}

validate_datapage_checksums ()
{
	CHECKSUM="$1"
	if [ "$CHECKSUM" != "" -a $PGMAJOR -lt 93 ]; then
		HINT="You must run \"$PROGNAME\" with PostgreSQL >=9.3"
		elog "data page checksums is NOT supported in $PGVERSION" "$HINT"
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

prepare_psql ()
{
	PGPORT=$(show_guc "port" $PGCONF)
	PSQLOPT=""
	if [ ! -z "$PGPORT" ]; then
		PSQLOPT="-p $PGPORT"
	fi
	PSQL="$PGBIN/psql $PSQLOPT"
}

set_guc ()
{
	GUCNAME="$1"
	GUCVALUE="$2"
	CONFPATH="$3"

	PREVALUE="$(show_guc $GUCNAME $CONFPATH)"
	if [ ! -z "$PREVALUE" ]; then
		remove_line "^$GUCNAME" $CONFPATH
		echo "$GUCNAME = $GUCVALUE" >> $CONFPATH
	fi
}

show_guc ()
{
	GUCNAME="$1"
	CONFPATH="$2"

	grep -E ^$GUCNAME\ \|\#$GUCNAME\  $CONFPATH | \
		cut -f1 |\
		awk -F" = " 'NR==1 {v=$2} NR!=1 && $1!~"#" {v=$2} END { if (v!="") print v}'
}

find_all_pgdata ()
{
	MUSTHAVE="base global pg_subtrans"

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

pm_pids ()
{
	for pmppid in 1 $(pgrep -x "pg_ctl") $(pgrep -P 1 -f "postmaster exit status is"); do
		pgrep -P $pmppid -x "postgres|postmaster"
	done
}
