#!/bin/sh

. pgcommon.sh

METAFILE=/tmp/pgdownloader.tmp

BASEURL="https://ftp.postgresql.org/pub/source"
SRCVERSION=LATEST
SRCEXT=tar.bz2

usage ()
{
cat <<EOF
$PROGNAME downloads PostgreSQL source code tarball.

Usage:
  $PROGNAME [VERSION]

Notes:
  If VERSION is not specified, the latest minor version will be downloaded.
  If a major version like 9.5 is specified in VERSION,
  the latest minor version of the specified major one will be downloaded.
EOF
}

is_minor_version ()
{
	echo $SRCVERSION | grep -E "(^[6-9]\.[0-9]+\.[0-9]+$)|(^[1-9][0-9]\.[0-9]+$)"
}

is_major_version ()
{
	echo $SRCVERSION | grep -E "(^[6-9]\.[0-9]+$)|(^[1-9][0-9]$)"
}

validate_minor_version ()
{
	if [ -z "$(is_minor_version)" ]; then
		elog "invalid PostgreSQL minor version: ${SRCVERSION}"
	fi

	grep "\"v${SRCVERSION}/\"" $METAFILE > /dev/null
	if [ $? -ne 0 ]; then
		elog "could not find version ${SRCVERSION} source file in PostgreSQL source repository site"
	fi
}

download_source ()
{
	validate_minor_version

	SRCFILE=postgresql-${SRCVERSION}.${SRCEXT}
	wget ${BASEURL}/v${SRCVERSION}/${SRCFILE}
	if [ $? -ne 0 ]; then
		elog "could not download source file \"${SRCFILE}\""
	fi
	exit 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			SRCVERSION="$1";;
	esac
	shift
done

wget $BASEURL -O $METAFILE > $TMPFILE 2>&1
if [ $? -ne 0 ]; then
	cat $TMPFILE
	rm -f $TMPFILE
	elog "could not access to PostgreSQL source repository site"
fi
rm -f $TMPFILE

if [ ! -z "$(is_minor_version)" ]; then
	download_source
fi

if [ ! -z "$(is_major_version)" ]; then
	SORTPOS=3
	if [ ${SRCVERSION} -ge 10 ]; then
		SORTPOS=2
	fi
	TMPVERSION=$(grep -E "\"v${SRCVERSION}.[0-9]+/\"" $METAFILE | cut -dv -f2 | cut -d/ -f1 | sort -t. -k${SORTPOS} -n | tail -1)
	if [ -z $TMPVERSION ]; then
		elog "could not find any source file of major version ${SRCVERSION} in PostgreSQL source repository site"
	fi
	SRCVERSION=$TMPVERSION
	download_source
fi

if [ "$SRCVERSION" = "LATEST" ]; then
	TMPVERSION=$(grep -E "v[0-9]+\.[0-9]+" $METAFILE | cut -dv -f2 | cut -d/ -f1 | sort -n | tail -1)
	if [ -z $TMPVERSION ]; then
		elog "could not find any source file in PostgreSQL source repository site"
	fi
	SRCVERSION=$TMPVERSION
	download_source
fi

elog "invalid PostgreSQL version: ${SRCVERSION}"
