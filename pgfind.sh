#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME prints the lines matching PATTERN"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] PATTERN"
	echo ""
	echo "Default:"
	echo "  This utility searches in source code directory"
	echo ""
	echo "Options:"
	echo "  -a, --all         searches in both source code and document directory"
	echo "  -c, --contrib     searches in contrib directory"
	echo "  -d, --document    searches in document directory"
}

ALL_MODE="FALSE"
CONTRIB_MODE="FALSE"
DOC_MODE="FALSE"
PATTERN=
while [ $# -gt 0 ]; do
	case "$1" in
		-a|--all)
			ALL_MODE="TRUE";;
		-c|--contrib)
			CONTRIB_MODE="TRUE";;
		-d|--document)
			DOC_MODE="TRUE";;
		-h|--help|"-\?")
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			PATTERN="$1";;
	esac
	shift
done

here_is_source

if [ -z "$PATTERN" ]; then
	elog "PATTERN must be supplied"
fi

if [ "$ALL_MODE" = "TRUE" ]; then
	$PROGNAME "$PATTERN"
	$PROGNAME -c "$PATTERN"
	$PROGNAME -d "$PATTERN"
	exit
fi

REGEXP=
SEARCHPATH=
if [ "$DOC_MODE" = "TRUE" ]; then
	REGEXP="*.sgml"
	SEARCHPATH=doc
elif [ "$CONTRIB_MODE" = "TRUE" ]; then
	REGEXP="*.[chy]"
	SEARCHPATH=contrib
else
	REGEXP="*.[chy]"
	SEARCHPATH=src
fi

find $SEARCHPATH -name "$REGEXP" -exec grep -H "$PATTERN" {} \;
