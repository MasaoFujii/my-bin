#!/bin/sh

. pgcommon.sh

SEARCH_ALL="FALSE"
SEARCH_DIR=src
PATTERN=
REGEXP="*.[chy]"
GF_OPTS=

usage ()
{
cat <<EOF
$PROGNAME prints lines matching PATTERN

Usage:
  $PROGNAME [OPTIONS] PATTERN

Options:
  -a    searches in all
  -c    searches in contrib
  -d    searches in document
  -h    searches in header files
  -i    ignore case distinctions in PATTERN
  -s    searches in source (default)
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a)
			SEARCH_ALL="TRUE";;
		-c)
			SEARCH_DIR=contrib
			REGEXP="*.[chy]";;
		-d)
			SEARCH_DIR=doc
			REGEXP="*.sgml";;
		-i)
			GF_OPTS="$GF_OPTS -i";;
		-h)
			SEARCH_DIR=src
			REGEXP="*.h";;
		-s)
			SEARCH_DIR=src
			REGEXP="*.[chy]";;
		-*)
			elog "invalid option: $1";;
		*)
			if [ ! -z "$PATTERN" ]; then
				elog "too many arguments"
			fi
			PATTERN="$1"
			;;
	esac
	shift
done

here_is_source

if [ -z "$PATTERN" ]; then
	elog "PATTERN must be supplied"
fi

if [ "$SEARCH_ALL" = "TRUE" ]; then
	$PROGNAME $GF_OPTS -s "$PATTERN"
	$PROGNAME $GF_OPTS -c "$PATTERN"
	$PROGNAME $GF_OPTS -d "$PATTERN"
	exit 0
fi

grepfind.sh -d $SEARCH_DIR $GF_OPTS "$PATTERN" "$REGEXP"
