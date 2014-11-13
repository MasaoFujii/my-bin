#!/bin/sh

. pgcommon.sh

usage ()
{
	cat <<EOF
$PROGNAME creates some useful functions.

Usage:
  $PROGNAME [PGDATA]

Functions:
  random_text (num int)    generate the specified number random text
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists
pgsql_is_alive

prepare_psql

cat <<EOF | $PSQL
CREATE OR REPLACE FUNCTION random_text (num int) RETURNS text AS \$\$
DECLARE
    result text := '';
BEGIN
    LOOP
        IF num = 0 THEN
				    EXIT;
			  ELSE
				    num = num - 1;
        END IF;
        result := result || chr(floor(random() * 95)::int + 32);
    END LOOP;

		RETURN result;
END
\$\$ LANGUAGE plpgsql;
EOF
