#!/bin/sh

. pgcommon.sh

LOGFILE=/tmp/pgxsmake.log

PREFIX=
MAKECMD=
MAKEFLG=
MAKEALL="FALSE"

usage ()
{
cat <<EOF
$PROGNAME compiles and installs PostgreSQL module with PGXS.

Usage:
  $PROGNAME [OPTIONS] PREFIX [COMMAND]

Default:
  runs plain "make" command.

Options:
  -a, --all          runs "make uninstall, clean and install"
  -c, --clean        runs "make clean"
  -f, --flag=FLAG    uses FLAG, e.g., -f "SENNA_CFG=/opt/senna-cfg"
  -i, --install      runs "make install"
  -u, --uninstall    runs "make uninstall"
  --check            runs "make check"
  --installcheck     runs "make installcheck"
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a|--all)
			MAKEALL="TRUE";;
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
			if [ -z "$PREFIX" ]; then
				PREFIX="$1"
			elif [ -z "$MAKECMD" ]; then
				MAKECMD="$1"
			else
				elog "too many arguments"
			fi
			;;
	esac
	shift
done

if [ ! -f $CURDIR/Makefile ]; then
	elog "here is NOT module source directory: \"$CURDIR\""
fi

if [ -z "$PREFIX" ]; then
	elog "PREFIX must be supplied"
fi

if [ "$MAKEALL" = "TRUE" ]; then
	FLGOPT=
	if [ ! -z "$MAKEFLG" ]; then
		FLGOPT="-f"
	fi
	pgxsmake.sh $FLGOPT "$MAKEFLG" $PREFIX uninstall
	pgxsmake.sh $FLGOPT "$MAKEFLG" $PREFIX clean
	pgxsmake.sh $FLGOPT "$MAKEFLG" $PREFIX
	pgxsmake.sh $FLGOPT "$MAKEFLG" $PREFIX install
	exit 0;
fi

export LANG=C
make USE_PGXS=1 PG_CONFIG=$PREFIX/bin/pg_config $MAKEFLG $MAKECMD > $LOGFILE 2>&1

cat $LOGFILE
echo -e "\n"
grep -a warning $LOGFILE
