#!/bin/sh

. bincommon.sh

GREP_PATTERN=
GREP_OPTIONS=
FIND_PATTERN="*"
SEARCH_DIR="."
EXCLUDE="-name .git -prune -or"
SHOWFILENAME="TRUE"

usage ()
{
cat <<EOF
$PROGNAME prints lines matching GREP_PATTERN from files matching FIND_PATTERN.

Usage:
  $PROGNAME [OPTIONS] GREP_PATTERN [FIND_PATTERN]
Options:
  -d DIR    where to search (default: .)
  -i        ignore case distinctions in GREP_PATTERN
  -k        show neither filename nor line number
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-d)
			SEARCH_DIR="$2"
			shift;;
		-i)
			GREP_OPTIONS="$GREP_OPTIONS -i";;
		-k)
			SHOWFILENAME="FALSE";;
		-*)
			elog "invalid option: $1";;
		*)
			if [ -z "$GREP_PATTERN" ]; then
				GREP_PATTERN="$1"
			elif [ "$FIND_PATTERN" = "*" ]; then
				FIND_PATTERN="$1"
			else
				elog "too many arguments"
			fi
			;;
	esac
	shift
done

if [ -z "$GREP_PATTERN" ]; then
	elog "GREP_PATTERN must be supplied"
fi

if [ "$SHOWFILENAME" = "TRUE" ]; then
	GREP_OPTIONS="$GREP_OPTIONS -Hn"
fi

find $SEARCH_DIR $EXCLUDE -name "$FIND_PATTERN" -type f -exec grep $GREP_OPTIONS "$GREP_PATTERN" {} \;
