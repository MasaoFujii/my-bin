#!/bin/sh

. pgcommon.sh

GITCMD=
ARGV1=
ARGV2=
SUPPORTED_VERS="_19 _18 _17 _16 _15"

GITHUB=github
AUTOTEST=autotest
WTDIR=/dav/worktree

usage ()
{
cat <<EOF
$PROGNAME performs Git operations in a local PostgreSQL repository.

Usage:
  $PROGNAME [COMMAND [ARGUMENTS...]]

Commands:
  am PATCH                    creates a branch from updated master and runs git am PATCH
  amend                       amends the latest commit with tracked changes and message "amend"
  apply PATCH                 creates a branch from updated master and applies PATCH
  autotest [cirrus|remove]    pushes a test branch to $GITHUB for GitHub Actions
                              (cirrus also enables Cirrus CI; remove deletes remote test branches)
  branch, b                   lists local branches
  cherry-pick PATTERN...      applies the original branch's HEAD to matching branches in order
                              (stops on failure and aborts a failed cherry-pick)
  co [PATTERN]                switches to a matching branch (default: master)
  committer [SINCE [UNTIL]]   counts commits by author, optionally within a date range
  create BRANCH               creates and switches to BRANCH from HEAD
  diff [TARGET]               runs git diff with an optional target
                              (default: unstaged changes)
  docs                        builds HTML documentation
  grep [-i] PATTERN           searches tracked files for PATTERN (-i ignores case)
  help                        shows this help (default command)
  log [PATTERN]               shows commit logs, optionally filtering commit messages by PATTERN
  make                        builds and installs the current branch into /dav/<branch-name>
  merge                       updates master from origin and merges it into the current branch
  patch [FILE]                writes a diff against master to /dav/FILE
                              (default: <branch-name>.patch)
  pgindent [COMMIT]           runs pgindent on files changed relative to COMMIT (default: HEAD)
  pgperltidy FILE             runs pgperltidy on FILE
  pull                        pulls the current branch from $GITHUB
  push                        pushes the current branch to $GITHUB and sets its upstream
  remove [BRANCH]             deletes BRANCH and /dav/BRANCH (default: current branch)
  rename NAME                 renames the current branch to NAME
  reset [COMMIT]              hard-resets the current branch, index and working tree to COMMIT
                              (default: HEAD)
  restore FILE COMMIT         restores FILE in the working tree and index to COMMIT
  stable [remove]             creates local pg<version> branches from supported stable branches
                              (remove deletes those local branches and their installations)
  stable cherry-pick          applies the original branch's HEAD to pg<version> branches
                              (in SUPPORTED_VERS order; stops and aborts on cherry-pick failure)
  untrack [clean]             lists untracked files and directories, including ignored ones
                              (clean deletes them)
  update, u [all]             updates master from origin (all also updates supported stable branches)
  wip                         commits tracked changes with message "wip"
  wt add|remove BRANCH        adds or removes a worktree for BRANCH under $WTDIR
                              (BRANCH=stable selects all supported pg<version> branches)

An unrecognized COMMAND is treated as a branch pattern and switches to a
matching branch if one exists.
EOF
}

for ARG in "$@"; do
	case "$ARG" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			if [ -z "$GITCMD" ]; then
				GITCMD="$ARG"
			elif [ -z "$ARGV1" ]; then
				ARGV1="$ARG"
			elif [ -z "$ARGV2" ]; then
				ARGV2="$ARG"
			fi
			;;
	esac
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
	BRANCH_LIST=$(git branch --no-color) || return 1
	BRANCH_NAMES=$(printf '%s\n' "$BRANCH_LIST" | cut -c3-)
	MOVETO=$(printf '%s\n' "$BRANCH_NAMES" | grep -m 1 -- "$1")
	for BACKBRANCH in $(printf '%s\n' "$BRANCH_NAMES" | grep -E '^REL[_0-9]*STABLE$'); do
		if printf '%s\n' "$BACKBRANCH" | tr -d '_' | grep -q -- "$1"; then
			MOVETO="$BACKBRANCH"
			break
		fi
	done
	if [ ! -z "$MOVETO" ]; then
		if printf '%s\n' "$BRANCH_LIST" | grep -F -x -q -- "+ $MOVETO"; then
			cd "${WTDIR}/$MOVETO"
		else
			git checkout "$MOVETO"
		fi
	else
		return 1
	fi
}

do_cherry_pick ()
{
	LATESTCOMMIT=$(git rev-parse --verify HEAD) || exit 1
	for PATTERN in "$@"; do
		if [ -z "$PATTERN" ] || ! move_to_branch "$PATTERN"; then
			elog "could not switch to branch matching \"$PATTERN\""
		fi
		git branch
		git cherry-pick "$LATESTCOMMIT"
		CHERRY_PICK_STATUS=$?
		if [ "$CHERRY_PICK_STATUS" -ne 0 ]; then
			git cherry-pick --abort
			exit "$CHERRY_PICK_STATUS"
		fi
	done
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
	BUILDYML=ci-linux.yml
	WORKFLOWS=.github/workflows
	COMMITMSG="Add files to build and test on GitHub Actions."
	NEWBRANCH="$1"

	mkdir -p $WORKFLOWS
	cp $PROGDATA/$BUILDYML $WORKFLOWS
	git add $WORKFLOWS/$BUILDYML

	git commit -a -m "${COMMITMSG}"
	git push $GITHUB $NEWBRANCH

	git checkout master
	git branch -D $NEWBRANCH
	back_to_current
}

do_autotest_remove ()
{
	git fetch $GITHUB --prune
	for BRANCH_TO_RM in $(git branch -r | grep "${GITHUB}/${AUTOTEST}_" | cut -d/ -f2- | grep -E ^"${AUTOTEST}_"); do
		git push --delete ${GITHUB} ${BRANCH_TO_RM}
	done
	git fetch $GITHUB --prune
}

skip_cirrus_test ()
{
	COMMITMSG="Skip tests on Cirrus."

	if [ ! -f .cirrus.star ]; then
		return;
	fi

	git rm .cirrus.star
	git rm .cirrus.tasks.yml
	git rm .cirrus.yml

	git commit -a -m "${COMMITMSG}"
}

if [ "$GITCMD" = "am" ]; then
	if [ -z "$ARGV1" ]; then
		elog "PATCH must be specified in \"am\" command"
	fi
	PATCHPATH="$ARGV1"
	NEWBRANCH=$(basename $PATCHPATH .patch)
	create_new_branch $NEWBRANCH
	git am $PATCHPATH
	git branch

elif [ "$GITCMD" = "amend" ]; then
	git commit --amend -a -m "amend"

elif [ "$GITCMD" = "apply" ]; then
	if [ -z "$ARGV1" ]; then
		elog "PATCH must be specified in \"apply\" command"
	fi
	PATCHPATH="$ARGV1"
	NEWBRANCH=$(basename $PATCHPATH .patch)
	create_new_branch $NEWBRANCH
	patch -p1 -d. < $PATCHPATH
	git status
#	pgetags.sh
	git branch

elif [ "$GITCMD" = "autotest" ]; then
 	github_is_available
	if [ "$ARGV1" = "remove" ]; then
		do_autotest_remove
	else
		current_must_not_have_uncommitted
		echo $CURBRANCH | grep -E "^${AUTOTEST}_" > /dev/null
		if [ $? -eq 0 ]; then
			elog "current branch must NOT be one created by previous autotest"
		fi
		COMMIT_ID=$(git rev-parse --short HEAD)
		NEWBRANCH="${AUTOTEST}_${CURBRANCH}_${CURTIME}_${COMMIT_ID}"
		git checkout -b "$NEWBRANCH"

		if [ "$ARGV1" != "cirrus" ]; then
			skip_cirrus_test
		fi
		do_autotest "$NEWBRANCH"
	fi

elif [ "$GITCMD" = "b" -o "$GITCMD" = "branch" ]; then
	git branch

elif [ "$GITCMD" = "cherry-pick" ]; then
	shift
	if [ $# -eq 0 ]; then
		elog "PATTERN must be specified in \"cherry-pick\" command"
	fi
	do_cherry_pick "$@"

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

elif [ "$GITCMD" = "docs" ]; then
	pgmake.sh -j 8 --libxml -d --configure /dav/$CURBRANCH
	make html

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
	pgmake.sh -j 8 --libxml -d /dav/$CURBRANCH

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

elif [ "$GITCMD" = "pgindent" ]; then
	COMMIT_ID=HEAD
	if [ ! -z "$ARGV1" ]; then
		COMMIT_ID="$ARGV1"
	fi
	TOOLSDIR=$CURDIR/src/tools
	PGINDENT=$TOOLSDIR/pgindent/pgindent
	PGBSDINDENT=$TOOLSDIR/pg_bsd_indent/pg_bsd_indent
	if [ ! -f $PGBSDINDENT ]; then
		HEADSRC=~/pgsql/head
		PGBSDINDENT=$HEADSRC/src/tools/pg_bsd_indent/pg_bsd_indent
	fi
	MODIFIED=$(git diff --diff-filter=ACMR --name-only "$COMMIT_ID")
	$PGINDENT --indent $PGBSDINDENT $MODIFIED

elif [ "$GITCMD" = "pgperltidy" ]; then
	if [ -z "$ARGV1" ]; then
		elog "PATH must be specified in \"pgperltidy\" command"
	fi
	PERLFILE="$ARGV1"
	TOOLSDIR=$CURDIR/src/tools
	PGPERLTIDY=$TOOLSDIR/pgindent/pgperltidy
	SEDOPT=
	if [ "$KERNEL" = "Darwin" ]; then
		SEDOPT="'.bak'"
	fi
	sed -i $SEDOPT 's/exit/#exit/g' $PGPERLTIDY
	$PGPERLTIDY $PERLFILE
	sed -i $SEDOPT 's/#exit/exit/g' $PGPERLTIDY

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

elif [ "$GITCMD" = "restore" ]; then
	if [ -z "$ARGV1" ]; then
		elog "FILE must be specified in \"restore\" command"
	fi
	if [ -z "$ARGV2" ]; then
		elog "COMMIT must be specified in \"restore\" command"
	fi
	git restore --source="$ARGV2" --staged --worktree -- "$ARGV1"

elif [ "$GITCMD" = "stable" -a "$ARGV1" = "cherry-pick" ]; then
	set --
	for PGVERSION in $SUPPORTED_VERS; do
		set -- "$@" "^pg${PGVERSION#_}$"
	done
	do_cherry_pick "$@"

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
			git branch "$DSTBRANCH" "$SRCBRANCH"
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
	if [ "$ARGV1" = "all" ]; then
		git fetch origin || exit 1
		set -- master
		for PGVERSION in $SUPPORTED_VERS; do
			set -- "$@" "REL${PGVERSION}_STABLE"
		done
		for BRANCH in "$@"; do
			if ! git merge-base --is-ancestor "$BRANCH" "refs/remotes/origin/$BRANCH"; then
				elog "local branch \"$BRANCH\" is not an ancestor of origin/$BRANCH"
			fi
			if [ "$BRANCH" = "$CURBRANCH" ]; then
				git merge --ff-only "refs/remotes/origin/$BRANCH" || exit 1
			else
				git branch -f "$BRANCH" "refs/remotes/origin/$BRANCH" || exit 1
			fi
		done
	else
		update_branch master
		back_to_current
	fi

elif [ "$GITCMD" = "wip" ]; then
	git commit -a -m "wip"

elif [ "$GITCMD" = "wt" ]; then
	if [ "$ARGV2" = "stable" ]; then
		for PGVERSION in $(echo "$SUPPORTED_VERS"); do
			TARGET="pg$(echo ${PGVERSION} | tr -d "\_")"
			if [ "$ARGV1" = "add" ]; then
				git worktree add ${WTDIR}/${TARGET} ${TARGET}
			elif [ "$ARGV1" = "remove" ]; then
				git worktree remove ${TARGET}
			fi
		done
	else
		if [ "$ARGV1" = "add" -a ! -z "$ARGV2" ]; then
			git worktree add ${WTDIR}/${ARGV2}
		elif [ "$ARGV1" = "remove" -a ! -z "$ARGV2" ]; then
			git worktree remove ${ARGV2}
		fi
	fi
	git worktree list

else
	move_to_branch "$GITCMD"
	git branch
fi
