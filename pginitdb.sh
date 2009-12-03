#!/bin/sh

. pgcommon.sh

Usage ()
{
	UsageForHelpOption "creates an initial database cluster"
}

SetupMinimalSettings ()
{
	if [ $PGMAJOR -le 74 ]; then
		SetOneGuc tcpip_socket true ${PGCONF}
	else
		SetOneGuc listen_addresses "'*'" ${PGCONF}
	fi
	SetOneGuc checkpoint_segments 64 ${PGCONF}
	echo "host	all	all	0.0.0.0/0	trust" >> ${PGHBA}
}

CurDirIsPgsqlIns

ParsingForHelpOption ${@}
GetPgData ${@}

PgsqlMustNotRunning
rm -rf ${PGDATA}

PGLOCALE=C
PGENCODING=UTF8
${PGBIN}/initdb -D ${PGDATA} --locale=${PGLOCALE} --encoding=${PGENCODING}
SetupMinimalSettings
