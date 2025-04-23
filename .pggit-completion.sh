_pggit()
{
	. .completion-common.sh

	case "$PREVWORD" in
		co)
			WORDLIST=$(git branch 2> /dev/null | tr -d "* ")
			if [ $? -ne 0 ]; then
				return 0
			fi;;
		remove)
			WORDLIST=$(git branch 2> /dev/null | tr -d "* ")
			if [ $? -ne 0 ]; then
				return 0
			fi;;
		stable)
			WORDLIST="remove";;
		untrack)
			WORDLIST="clean";;
		update|u)
			WORDLIST="all";;
		pggit.sh)
			WORDLIST="apply autotest branch cherry-pick co \
committer create diff docs grep help log make merge \
patch pgindent pull push remove rename reset stable untrack update wip";;
	esac

	mycompgen
}

complete -o bashdefault -o default -F _pggit pggit.sh
