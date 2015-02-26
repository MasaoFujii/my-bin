_pgconf()
{
	. .completion-common.sh

	if [ "$PREVWORD" != "-c" -a "$PREVWORD" != "-d" -a "$PREVWORD" != "-s" ]; then
		COMPREPLY=( $(compgen -f ${CURWORD}) )
		return 0
	fi

	WORDLIST=$(pgconf.sh --showall 2> /dev/null)
	if [ $? -ne 0 ]; then
		return 0
	fi

	mycompgen
}

complete -F _pgconf pgconf.sh
