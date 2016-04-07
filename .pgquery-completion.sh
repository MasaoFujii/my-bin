_pgquery()
{
	. .completion-common.sh

	case "$PREVWORD" in
		stat)
			WORDLIST="activity replication wal_receiver ssl archiver bgwriter database \
database_conflicts progress_vacuum";;
		pgquery.sh)
			WORDLIST="stat switch";;
	esac

	mycompgen
}

complete -o bashdefault -o default -F _pgquery pgquery.sh
