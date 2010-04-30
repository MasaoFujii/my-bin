#!/bin/sh

. pgcommon.sh

Usage ()
{
	UsageForHelpOption "creates an initial database cluster"
}

SetupMinimalSettings ()
{
	if [ $PGMAJOR -le 74 ]; then
		set_guc tcpip_socket true ${PGCONF}
	else
		set_guc listen_addresses "'*'" ${PGCONF}
	fi
	set_guc checkpoint_segments 64 ${PGCONF}
	echo "host	all	all	0.0.0.0/0	trust" >> ${PGHBA}
}

here_is_installation

ParsingForHelpOption ${@}
GetPgData ${@}

PgsqlMustNotRunning
rm -rf ${PGDATA}

PGLOCALE=C
PGENCODING=UTF8
${PGBIN}/initdb -D ${PGDATA} --locale=${PGLOCALE} --encoding=${PGENCODING}
SetupMinimalSettings
