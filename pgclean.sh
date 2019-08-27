#!/bin/sh

. pgcommon.sh

ONLY_MAINTAINER="FALSE"

usage ()
{
cat <<EOF
$PROGNAME cleans up PostgreSQL source directory.

Usage:
  $PROGNAME [OPTIONS]

Default:
  runs "make maintainer-clean" and removes junk files.

Options:
  -m, --maintainer  only runs "make maintainer-clean"
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-m|--maintainer)
	    ONLY_MAINTAINER="TRUE";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_source

make -s maintainer-clean

if [ "$ONLY_MAINTAINER" = "FALSE" ]; then
	find . -name "TAGS"   -exec rm -f {} \;
	find . -name "*~"     -exec rm -f {} \;
	find . -name "*.orig" -exec rm -f {} \;
	find . -name "*.rej"  -exec rm -f {} \;
fi
