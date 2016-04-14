CURWORD="${COMP_WORDS[COMP_CWORD]}"
PREVWORD="${COMP_WORDS[COMP_CWORD-1]}"

WORDLIST=""
COMPREPLY=()

mycompgen ()
{
	if [ ! -z "$WORDLIST" ]; then
		COMPREPLY=( $(compgen -W "$WORDLIST" $CURWORD) )
	fi
}
