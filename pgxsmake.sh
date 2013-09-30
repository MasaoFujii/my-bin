#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgxsmake.log

PREFIX=
MAKECMD=
MAKEFLG=

usage ()
{
cat <<EOF
$PROGNAME compiles and installs PostgreSQL module with PGXS.

Usage:
  $PROGNAME [OPTIONS] PREFIX

Default:
  runs plain \"make\" command.

Options:
  -c, --clean        runs \"make clean\"
  -C CMD             runs \"make CMD\"
  -f, --flag=FLAG    uses FLAG, e.g., -f \"SENNA_CFG=/opt/senna-cfg\"
  -i, --install      runs \"make install\"
  -u, --uninstall    runs \"make uninstall\"
  --check            runs \"make check\"
  --installcheck     runs \"make installcheck\"
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-c|--clean)
			MAKECMD="clean";;
		-C)
			MAKECMD="$2"
			shift;;
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
