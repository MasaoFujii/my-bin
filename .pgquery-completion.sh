_pgquery()
{
	. .completion-common.sh

	case "$PREVWORD" in
		location)
			WORDLIST="flush insert receive replay write";;
		replay)
			WORDLIST="is_paused pause resume timestamp";;
		stat)
			WORDLIST="activity replication wal_receiver ssl archiver bgwriter database \
database_conflicts progress_vacuum";;
		pgquery.sh)
			WORDLIST="location replay stat switch";;
	esac

	mycompgen
}

complete -o bashdefault -o default -F _pgquery pgquery.sh
