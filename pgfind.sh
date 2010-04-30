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
	echo "  -d, --document    searches in document directory"
}

DOC_MODE="FALSE"
PATTERN=
while [ $# -gt 0 ]; do
	case "$1" in
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

REGEXP=
SEARCHPATH=
if [ "$DOC_MODE" = "TRUE" ]; then
	REGEXP="*.sgml"
	SEARCHPATH=doc
else
	REGEXP="*.[chy]"
	SEARCHPATH=src
fi

find $SEARCHPATH -name "$REGEXP" -exec grep -H "$PATTERN" {} \;
