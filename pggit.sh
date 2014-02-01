#!/bin/sh

. pgcommon.sh

GITCMD=
ARGV1=
SUPPORTED_VERS="9_3 9_2 9_1 9_0 8_4"

usage ()
{
cat <<EOF
$PROGNAME does git operations in PostgreSQL local git repository.

Usage:
  $PROGNAME [COMMAND]

Command:
  apply PATCH       creates new branch and applies PATCH
  help              shows help message (default)
  make              compiles and installs current branch into /dav/<branch-name>
  merge             updates master and merges it into current branch
  patch [PATCH]     creates patch with name PATCH against master in /dav
  push              pushes current branch to github
  remove            removes current branch and moves to master
  reset             resets current branch to HEAD
  u[pdate]          updates master
  update-all        updates master and all supported versions
  wip               commits current change with message "wip"
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
			elif [ -z "$ARGV1" ]; then
				ARGV1="$1"
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

if [ "$GITCMD" = "apply" ]; then
	if [ -z "$ARGV1" ]; then
		elog "PATCH must be specified in \"patch\" command"
	fi
	PATCHPATH="$ARGV1"
	NEWBRANCH=$(basename $PATCHPATH .patch)
	current_must_not_have_uncommitted
	git checkout master
	git pull -u origin master
	git checkout -b $NEWBRANCH
	pgclean.sh -a
	patch -p1 -d. < $PATCHPATH
	git status
	pgetags.sh

elif [ "$GITCMD" = "" -o "$GITCMD" = "help" ]; then
	usage
	exit 0

elif [ "$GITCMD" = "make" ]; then
	pgmake.sh -j 2 -d /dav/$CURBRANCH

elif [ "$GITCMD" = "merge" ]; then
	current_must_not_have_uncommitted
	git checkout master
	git pull -u origin master
	back_to_current
	git merge master

elif [ "$GITCMD" = "patch" ]; then
	PATCHNAME="$CURBRANCH".patch
	if [ ! -z "$ARGV1" ]; then
		PATCHNAME="$ARGV1"
	fi
	git diff master | filterdiff --format=context > /dav/"$PATCHNAME"

elif [ "$GITCMD" = "push" ]; then
	git push -u github $CURBRANCH

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

elif [ "$GITCMD" = "wip" ]; then
	git commit -a -m "wip"

else
	elog "unsupported command was specified: $GITCMD"
fi
