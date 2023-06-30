#!/bin/sh

. pgcommon.sh

GITCMD=
ARGV1=
ARGV2=
SUPPORTED_VERS="_16 _15 _14 _13 _12 _11"

GITHUB=github

usage ()
{
cat <<EOF
$PROGNAME does git operations in PostgreSQL local git repository.

Usage:
  $PROGNAME [COMMAND]

Command:
  apply PATCH        creates new branch and applies PATCH
  autotest           builds and tests on AppVeyor, Travis CI and Github Actions
  [b]ranch           shows all local branches
  cherry-pick BRANCH applies the latest change in BRANCH
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
  remove [BRANCH]    removes branch and its installation directory
  rename NAME        renames current branch to NAME
  reset [TARGET]     resets current branch to HEAD (or TARGET)
  stable [remove]    clones all supported stable branches (or removes all clones)
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
	git clean -d -x -f
	git checkout -b "$1"
}

remove_branch ()
{
	BRANCH_TO_RM="$1"

	if [ ! "$(git branch --list ${BRANCH_TO_RM})" ]; then
		elog "branch \"$BRANCH_TO_RM\" not found"
	fi
	branches_must_exist "$BRANCH_TO_RM"
	if [ "$BRANCH_TO_RM" = "$CURBRANCH" ]; then
		git reset --hard HEAD
		git checkout master
	fi
	git branch -D $BRANCH_TO_RM
	if [ "$BRANCH_TO_RM" != "" ]; then
		rm -rf /dav/$BRANCH_TO_RM
	fi
}

move_to_branch ()
{
	MOVETO=$(git branch | cut -c3- | grep "$1" | head -1)
	for  BACKBRANCH in $(git branch | cut -c3- | grep -E "^REL[_0-9]*STABLE$"); do
	  echo $BACKBRANCH | tr -d '_' | grep "$1" > /dev/null
		if [ $? -eq 0 ]; then
			MOVETO="$BACKBRANCH"
			break
		fi
	done
	if [ ! -z "$MOVETO" ]; then
		git checkout $MOVETO
	fi
}

back_to_current ()
{
	git checkout $CURBRANCH
}

branches_must_exist ()
{
	THISBRANCH="$1"

	if [ "$THISBRANCH" = "master" ]; then
		elog "could not remove master branch"
	fi
	for PGVERSION in $(echo "$SUPPORTED_VERS"); do
		if [ "$THISBRANCH" = "REL${PGVERSION}_STABLE" ]; then
			elog "could not remove branch for supported version"
		fi
	done
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
	BUILDYML=ci-linux.yml
	WORKFLOWS=.github/workflows
	COMMITMSG="Add files to build and test on AppVeyor, Travis CI and Github Actions."
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

	mkdir -p $WORKFLOWS
	cp $PROGDATA/$BUILDYML $WORKFLOWS
	git add $WORKFLOWS/$BUILDYML

	git commit -a -m "${COMMITMSG}"
	git push $GITHUB $NEWBRANCH

	git checkout master
	git branch -D $NEWBRANCH
	back_to_current
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
	echo $CURBRANCH | grep -E "^${GITCMD}_" > /dev/null
	if [ $? -eq 0 ]; then
		elog "current branch must NOT be one created by previous autotest"
	fi
	COMMIT_ID=$(git rev-parse --short HEAD)
	NEWBRANCH="${GITCMD}_${CURBRANCH}_${CURTIME}_${COMMIT_ID}"
	git checkout -b "$NEWBRANCH"
	do_autotest "$NEWBRANCH"

elif [ "$GITCMD" = "b" -o "$GITCMD" = "branch" ]; then
	git branch

elif [ "$GITCMD" = "cherry-pick" ]; then
	if [ -z "$ARGV1" ]; then
		elog "BRANCH must be specified in \"cherry-pick\" command"
	fi
	LATESTCOMMIT=$(git log --abbrev-commit | head -1 | cut -d' ' -f2)
	move_to_branch "$ARGV1"
	git branch
	git cherry-pick "$LATESTCOMMIT"

elif [ "$GITCMD" = "co" ]; then
	if [ -z "$ARGV1" ]; then
		git checkout master
		git branch
	else
		move_to_branch "$ARGV1"
		git branch
	fi

elif [ "$GITCMD" = "committer" ]; then
	if [ -z "$ARGV1" ]; then
		git shortlog -sn
	elif [ -z "$ARGV2" ]; then
		git shortlog -sn --since="$ARGV1"
	else
		git shortlog -sn --since="$ARGV1" --until="$ARGV2"
	fi

elif [ "$GITCMD" = "create" ]; then
	if [ -z "$ARGV1" ]; then
		elog "BRANCH must be specified in \"create\" command"
	fi
	NEWBRANCH="$ARGV1"
	current_must_not_have_uncommitted
	git checkout -b "$NEWBRANCH"
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
	if [ $PGMAJOR -ge 160 ]; then
		pgmake.sh -j 8 --tap --libxml -c "--without-icu" -d /dav/$CURBRANCH
	else
		pgmake.sh -j 8 --tap --libxml -d /dav/$CURBRANCH
	fi

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
	git diff master --patience > /dav/"$PATCHNAME"

elif [ "$GITCMD" = "pull" ]; then
	git pull $GITHUB $CURBRANCH

elif [ "$GITCMD" = "push" ]; then
	git push -u $GITHUB $CURBRANCH

elif [ "$GITCMD" = "remove" ]; then
	BRANCH_TO_RM="$CURBRANCH"
	if [ ! -z "$ARGV1" ]; then
		BRANCH_TO_RM="$ARGV1"
	fi
	remove_branch "$BRANCH_TO_RM"
	git branch

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

elif [ "$GITCMD" = "stable" ]; then
	current_must_not_have_uncommitted
	for PGVERSION in $(echo "$SUPPORTED_VERS"); do
		SRCBRANCH="REL${PGVERSION}_STABLE"
		DSTBRANCH="pg$(echo ${PGVERSION} | tr -d "\_")"
		if [ "$ARGV1" = "remove" ]; then
			remove_branch "$DSTBRANCH"
		else
			if [ "$(git branch --list ${DSTBRANCH})" ]; then
				elog "branch \"$DSTBRANCH\" already exists"
			fi
			move_to_branch "$SRCBRANCH"
			git checkout -b "$DSTBRANCH"
		fi
	done
	git checkout master
	git branch

elif [ "$GITCMD" = "untrack" ]; then
	if [ "$ARGV1" = "clean" ]; then
		git clean -d -x -f
	else
		git clean -d -x -f --dry-run
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
	git branch
fi
