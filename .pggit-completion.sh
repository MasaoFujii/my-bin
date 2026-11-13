_pggit()
{
	local CURWORD PREVWORD WORDLIST
	. .completion-common.sh

	if [ "$COMP_CWORD" -eq 1 ]; then
		WORDLIST="am amend apply autotest b branch cherry-pick co \
committer create diff docs grep help log make merge \
patch pgindent pgperltidy pull push remove rename reset restore stable \
u untrack update wip wt"
	else
		case "${COMP_WORDS[1]}:$COMP_CWORD" in
			cherry-pick:*|co:2|remove:2)
				WORDLIST=$(git branch --format='%(refname:short)' 2> /dev/null);;
			autotest:2)
				WORDLIST="cirrus remove";;
			stable:2)
				WORDLIST="cherry-pick remove";;
			untrack:2)
				WORDLIST="clean";;
			update:2|u:2)
				WORDLIST="all";;
			wt:2)
				WORDLIST="add remove";;
			wt:3)
				case "${COMP_WORDS[2]}" in
					add|remove)
						WORDLIST="stable $(git branch --format='%(refname:short)' 2> /dev/null)";;
				esac;;
			diff:2|pgindent:2|reset:2|restore:3)
				WORDLIST="HEAD HEAD^ HEAD~ $(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes refs/tags 2> /dev/null)";;
		esac
	fi

	mycompgen
}

complete -o bashdefault -o default -F _pggit pggit.sh
