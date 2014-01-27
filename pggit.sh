#!/bin/sh

. pgcommon.sh

GITCMD=
SUPPORTED_VERS="9_3 9_2 9_1 9_0 8_4"

usage ()
{
cat <<EOF
$PROGNAME does git operations in PostgreSQL local git repository.

Usage:
  $PROGNAME [COMMAND]

Command:
  help            shows help message (default)
  merge-master    updates master and merges it into current branch
  remove          removes current branch and moves to master
  reset           resets current branch to HEAD
  u[pdate]        updates master
  update-all      updates master and all supported versions
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			if [ -z "$GITCMD" ]; then
				GITCMD="$1"
			else
				elog "too many arguments"
			fi
			;;
	esac
	shift
done

here_is_source

CURBRANCH=$(git branch | grep '^\*' | cut -b3-)

current_must_not_have_uncommitted ()
{
	DIFFLINE=$(git diff | wc -l)
	if [ $DIFFLINE -ne 0 ]; then
		elog "current branch has uncommitted changes"
	fi
}

update_branch ()
{
	GITBRANCH="$1"
	git checkout $GITBRANCH
	git pull -u origin $GITBRANCH
}

back_to_current ()
{
	git checkout $CURBRANCH
}

if [ "$GITCMD" = "" -o "$GITCMD" = "help" ]; then
	usage
	exit 0

elif [ "$GITCMD" = "merge-master" ]; then
	current_must_not_have_uncommitted
	git checkout master
	git pull -u origin master
	back_to_current
	git merge master

elif [ "$GITCMD" = "remove" ]; then
	if [ "$CURBRANCH" = "master" ]; then
		elog "could not remove master branch"
	fi
	git reset --hard HEAD
	git co master
	git b -D $CURBRANCH

elif [ "$GITCMD" = "reset" ]; then
	git reset --hard HEAD

elif [ "$GITCMD" = "u" -o "$GITCMD" = "update" ]; then
	current_must_not_have_uncommitted
	update_branch master
	back_to_current

elif [ "$GITCMD" = "update-all" ]; then
	current_must_not_have_uncommitted
	update_branch master
	for PGVERSION in $(echo "$SUPPORTED_VERS"); do
		update_branch "REL${PGVERSION}_STABLE"
	done
	back_to_current

else
	elog "unsupported command was specified: $GITCMD"
fi
