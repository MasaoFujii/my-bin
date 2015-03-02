_pggit()
{
	. .completion-common.sh

	case "$PREVWORD" in
		co)
			WORDLIST=$(git branch 2> /dev/null | tr -d "* ")
			if [ $? -ne 0 ]; then
				return 0
			fi;;
		untrack)
			WORDLIST="clean";;
		update|u)
			WORDLIST="all";;
		pggit.sh)
			WORDLIST="apply branch co committer create diff help log make merge \
patch pull push remove rename reset untrack update wip";;
	esac

	mycompgen
}

complete -o bashdefault -o default -F _pggit pggit.sh
