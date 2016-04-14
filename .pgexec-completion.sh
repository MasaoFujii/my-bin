find_dir ()
{
	for tmp in $(ls); do
		if [ -d $tmp ]; then
			echo $tmp
		fi
	done
}

_pgexec()
{
	. .completion-common.sh

	case "$PREVWORD" in
		location)
			WORDLIST="flush insert receive replay write";;
		pgdata)
			WORDLIST=$(find_dir);;
		replay)
			WORDLIST="is_paused pause resume timestamp";;
		stat)
			WORDLIST="activity replication wal_receiver ssl archiver bgwriter database \
database_conflicts progress_vacuum";;
		*)
			WORDLIST="location pgdata replay stat switch";;
	esac

	mycompgen
}

complete -o bashdefault -o default -F _pgexec pgexec.sh
