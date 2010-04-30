#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME opens the pg_hba.conf file with emacs"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [PGDATA]"
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation

emacs $PGHBA &
