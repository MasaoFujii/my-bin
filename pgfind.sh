#!/bin/sh

. pgcommon.sh

SEARCH_ALL="FALSE"
SEARCH_DIR=src
PATTERN=
REGEXP="*.[chy]"
GF_OPTS=

usage ()
{
	echo "$PROGNAME prints lines matching PATTERN"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] PATTERN"
	echo ""
	echo "Options:"
	echo "  -a    searches in all"
	echo "  -c    searches in contrib"
	echo "  -d    searches in document"
	echo "  -i    ignore case distinctions in PATTERN"
	echo "  -s    searches in source (default)"
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
	$PROGNAME -s "$PATTERN"
	$PROGNAME -c "$PATTERN"
	$PROGNAME -d "$PATTERN"
	exit 0
fi

grepfind.sh -d $SEARCH_DIR $GF_OPTS "$PATTERN" "$REGEXP"
