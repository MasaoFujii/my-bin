_pgconf()
{
	. .completion-common.sh

	case "$PREVWORD" in
		-c|-d|-s)
			WORDLIST=$(pgconf.sh --showall 2> /dev/null)
			if [ $? -ne 0 ]; then
				WORDLIST=""
			fi;;
	esac

	mycompgen
}

complete -o bashdefault -o default -F _pgconf pgconf.sh
