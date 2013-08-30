#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgxsmake.log

PREFIX=
MAKECMD=
MAKEFLG=

usage ()
{
	echo "$PROGNAME compiles and installs PostgreSQL module with PGXS."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] PREFIX"
	echo ""
	echo "Default:"
	echo "  runs \"make\" if neither -c, -i nor -u is specified."
	echo ""
	echo "Options:"
	echo "  -c, --clean        runs \"make clean\""
	echo "  -f, --flag=FLAG    uses FLAG, e.g., -f \"SENNA_CFG=/opt/senna-cfg\""
	echo "  -i, --install      runs \"make install\""
	echo "  -u, --uninstall    runs \"make uninstall\""
	echo "  --check            runs \"make check\""
	echo "  --installcheck     runs \"make installcheck\""
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-c|--clean)
			MAKECMD="clean";;
		-f|--flag)
			MAKEFLG="$2 $MAKEFLG"
			shift;;
		-i|--install)
			MAKECMD="install";;
		-u|--uninstall)
			MAKECMD="uninstall";;
		--check)
			MAKECMD="check";;
		--installcheck)
			MAKECMD="installcheck";;
		-*)
			elog "invalid option: $1";;
		*)
			PREFIX="$1";;
	esac
	shift
done

if [ ! -f $CURDIR/Makefile ]; then
	elog "here is NOT module source directory: \"$CURDIR\""
fi

if [ -z "$PREFIX" ]; then
	elog "PREFIX must be supplied"
fi

export LANG=C
make USE_PGXS=1 PG_CONFIG=$PREFIX/bin/pg_config $MAKEFLG $MAKECMD > $LOGFILE 2>&1

cat $LOGFILE
echo -e "\n"
grep -a warning $LOGFILE