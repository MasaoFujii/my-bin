#!/bin/sh

. pgcommon.sh

GITCMD=
ARGV1=
ARGV2=
SUPPORTED_VERS="_12 _11 _10 9_6 9_5 9_4 9_3"

GITHUB=github

usage ()
{
cat <<EOF
$PROGNAME does git operations in PostgreSQL local git repository.

Usage:
  $PROGNAME [COMMAND]

Command:
  apply PATCH        creates new branch and applies PATCH
  autotest           builds and tests on AppVeyor and Travis CI
  [b]ranch           shows all local branches
  co [PATTERN]       moves to branch matching PATTERN (master branch by default)
  committer          shows how many patches each committer committed
  create BRANCH      creates new branch named BRANCH
  diff [TARGET]      shows changes between commits, commit and working tree, etc
  grep [-i] PATTERN  prints lines matching PATTERN
  help               shows help message (default)
  log [PATTERN]      shows commit logs
  make               compiles and installs current branch into /dav/<branch-name>
  merge              updates master and merges it into current branch
  patch [PATCH]      creates patch with name PATCH against master in /dav
  pull               pulles current branch from $GITHUB
  push               pushes current branch to $GITHUB
  remove [cascade]   removes current branch (and its installation directory)
  rename NAME        renames current branch to NAME
  reset [TARGET]     resets current branch to HEAD (or TARGET)
  untrack [clean]    shows (or cleans up) all untracked objects
  u[pdate] [all]     updates master (and all supported versions)
  wip                commits current change with message "wip"

Move to branch matching COMMAND if it's not supported and there is branch
matching it.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			if [ -z "$GITCMD" ]; then
				GITCMD="$1"
			elif [ -z "$ARGV1" ]; then
				ARGV1="$1"
			elif [ -z "$ARGV2" ]; then
				ARGV2="$1"
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
	git checkout "$1"
	git pull origin "$1"
}

create_new_branch ()
{
	current_must_not_have_uncommitted
	update_branch master
	git clean -d -f
	git checkout -b "$1"
}

move_to_branch ()
{
	MOVETO=$(git branch | cut -c3- | grep "$1" | head -1)
	if [ ! -z "$MOVETO" ]; then
		git checkout $MOVETO
	fi
	git branch
}

back_to_current ()
{
	git checkout $CURBRANCH
}

github_is_available ()
{
	GITHUB_URL=git@github.com:MasaoFujii/postgresql.git

	git remote get-url $GITHUB | grep -E "^${GITHUB_URL}$" > /dev/null
	if [ $? -ne 0 ]; then
		elog "$GITHUB repository is NOT registered or its URL is invalid"
	fi
}

do_autotest ()
{
	CFBOT=~/pgsql/cfbot
	APPVEYOR=$CFBOT/appveyor
	TRAVIS=$CFBOT/travis
	COMMITMSG="Add files to build and test on AppVeyor and Travis CI."
	NEWBRANCH="$1"

	cd $CFBOT
	git pull
	cd $CURDIR

	for filename in $(ls -a $APPVEYOR); do
		if [ ! -f ${APPVEYOR}/${filename} ]; then
			continue
		fi
		cp ${APPVEYOR}/${filename} .
		git add $filename
	done

	for filename in $(ls -a $TRAVIS); do
		if [ ! -f ${TRAVIS}/${filename} ]; then
			continue
		fi
		cp ${TRAVIS}/${filename} .
		git add $filename
	done

	git commit -a -m "${COMMITMSG}"
	git push $GITHUB $NEWBRANCH
}

if [ "$GITCMD" = "apply" ]; then
	if [ -z "$ARGV1" ]; then
		elog "PATCH must be specified in \"patch\" command"
	fi
	PATCHPATH="$ARGV1"
	NEWBRANCH=$(basename $PATCHPATH .patch)
	create_new_branch $NEWBRANCH
	patch -p1 -d. < $PATCHPATH
	git status
	pgetags.sh
	git branch

elif [ "$GITCMD" = "autotest" ]; then
	github_is_available
	current_must_not_have_uncommitted
	COMMIT_ID=$(git rev-parse --short HEAD)
	NEWBRANCH="${GITCMD}_${CURBRANCH}_${CURTIME}_${COMMIT_ID}"
	git checkout -b "$NEWBRANCH"
	do_autotest "$NEWBRANCH"

elif [ "$GITCMD" = "b" -o "$GITCMD" = "branch" ]; then
	git branch

elif [ "$GITCMD" = "co" ]; then
	if [ -z "$ARGV1" ]; then
		git checkout master
		git branch
	else
		move_to_branch "$ARGV1"
	fi

elif [ "$GITCMD" = "committer" ]; then
	git shortlog -sn

elif [ "$GITCMD" = "create" ]; then
	if [ -z "$ARGV1" ]; then
		elog "BRANCH must be specified in \"create\" command"
	fi
	NEWBRANCH="$ARGV1"
	current_must_not_have_uncommitted
	git checkout -b "$NEWBRANCH"
	pgetags.sh
	git branch

elif [ "$GITCMD" = "diff" ]; then
	DIFFTARGET="$ARGV1"
	git diff $DIFFTARGET

elif [ "$GITCMD" = "grep" ]; then
	git grep $ARGV1 $ARGV2

elif [ "$GITCMD" = "" -o "$GITCMD" = "help" ]; then
	usage

elif [ "$GITCMD" = "log" ]; then
	if [ -z "$ARGV1" ]; then
		git log --abbrev-commit
	else
		git log --abbrev-commit --grep="${ARGV1}"
	fi

elif [ "$GITCMD" = "make" ]; then
	pgmake.sh -j 8 --tap --libxml --llvm -d /dav/$CURBRANCH

elif [ "$GITCMD" = "merge" ]; then
	current_must_not_have_uncommitted
	git checkout master
	git pull origin master
	back_to_current
	git merge master

elif [ "$GITCMD" = "patch" ]; then
	PATCHNAME="$CURBRANCH".patch
	if [ ! -z "$ARGV1" ]; then
		PATCHNAME="$ARGV1"
	fi
	git diff master | filterdiff --format=context > /dav/"$PATCHNAME"

elif [ "$GITCMD" = "pull" ]; then
	git pull $GITHUB $CURBRANCH

elif [ "$GITCMD" = "push" ]; then
	git push -u $GITHUB $CURBRANCH

elif [ "$GITCMD" = "remove" ]; then
	if [ "$CURBRANCH" = "master" ]; then
		elog "could not remove master branch"
	fi
	for PGVERSION in $(echo "$SUPPORTED_VERS"); do
		if [ "$CURBRANCH" = "REL${PGVERSION}_STABLE" ]; then
			elog "could not remove branch for supported version"
		fi
	done
	git reset --hard HEAD
	git co master
	git branch -D $CURBRANCH
	git branch
	if [ "$ARGV1" = "cascade" ]; then
		rm -rf /dav/$CURBRANCH
	fi

elif [ "$GITCMD" = "rename" ]; then
	if [ -z "$ARGV1" ]; then
		elog "NAME must be specified in \"rename\" command"
	fi
	NEWNAME="$ARGV1"
	current_must_not_have_uncommitted
	git checkout -b "$NEWNAME"
	git branch -D $CURBRANCH
	git branch

elif [ "$GITCMD" = "reset" ]; then
	RESETTARGET="HEAD"
	if [ ! -z "$ARGV1" ]; then
		RESETTARGET="$ARGV1"
	fi
	git reset --hard "$RESETTARGET"

elif [ "$GITCMD" = "untrack" ]; then
	if [ "$ARGV1" = "clean" ]; then
		git clean -d -f
	else
		git clean -d -f --dry-run
	fi

elif [ "$GITCMD" = "u" -o "$GITCMD" = "update" ]; then
	current_must_not_have_uncommitted
	update_branch master
	if [ "$ARGV1" = "all" ]; then
		for PGVERSION in $(echo "$SUPPORTED_VERS"); do
			update_branch "REL${PGVERSION}_STABLE"
		done
	fi
	back_to_current

elif [ "$GITCMD" = "wip" ]; then
	git commit -a -m "wip"

else
	move_to_branch "$GITCMD"
fi
