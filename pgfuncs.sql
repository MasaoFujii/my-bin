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
