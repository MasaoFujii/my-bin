-- Generate the specified number random text
CREATE OR REPLACE FUNCTION random_text (num int) RETURNS text AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION random_uppercase (num int) RETURNS text AS $$
DECLARE
    result text := '';
BEGIN
    LOOP
        IF num = 0 THEN
				    EXIT;
			  ELSE
				    num = num - 1;
        END IF;
        result := result || chr(floor(random() * 26)::int + 65);
    END LOOP;

		RETURN result;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION DROP_ALL_FUNCTIONS_ON_SCHEMA (schemaname TEXT)
RETURNS VOID AS $$
DECLARE
  row RECORD;
BEGIN
  FOR row IN EXECUTE
    'SELECT
       n.nspname,
       p.proname,
       pg_catalog.pg_get_function_arguments(p.oid) proargs
     FROM
       pg_catalog.pg_proc p LEFT JOIN pg_catalog.pg_namespace n
     ON
       n.oid = p.pronamespace
     WHERE
       n.nspname = ' || quote_literal(schemaname)
  LOOP
  RAISE NOTICE 'removing function %.%(%)',
    quote_ident(row.nspname),
    quote_ident(row.proname),
    row.proargs;
  EXECUTE 'DROP FUNCTION '
    || quote_ident(row.nspname) || '.'
    || quote_ident(row.proname) || '('
    || row.proargs || ')';
  END LOOP;
END;
$$ LANGUAGE plpgsql;
