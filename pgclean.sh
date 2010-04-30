#!/bin/sh

. pgcommon.sh

CLEAN_ALL="FALSE"
CLEAN_MAINTAINER="FALSE"

usage
{
	echo "$PROGNAME removes the useless files from source directory"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Default:"
	echo "  runs just \"make clean\""
	echo ""
	echo "Options:"
	echo "  -a, --all         runs \"make maintainer-clean\" and"
	echo "                    deletes all the useless files"
	echo "  -m, --maintainer  runs \"make maintainer-clean\""
}

while [ $# -gt 0 ]; do
	case "$1" in
		-a|--all)
			CLEAN_ALL="TRUE"
	    CLEAN_MAINTAINER="TRUE";;
		-h|--help|"-\?")
			usage
			exit 0;;
		-m|--maintainer)
	    CLEAN_MAINTAINER="TRUE";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_source

if [ "$CLEAN_MAINTAINER" = "TRUE" ]; then
	make maintainer-clean
else
	make clean
fi

if [ "$CLEAN_ALL" = "TRUE" ]; then
	find . -name "TAGS"   -exec rm -f {} \;
	find . -name "*~"     -exec rm -f {} \;
	find . -name "*.orig" -exec rm -f {} \;
	find . -name "*.rej"  -exec rm -f {} \;
fi
