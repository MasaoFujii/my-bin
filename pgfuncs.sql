-- Generate the specified number random text
CREATE OR REPLACE FUNCTION random_text (num int) RETURNS text AS $$
BEGIN
    IF num = 1 THEN
		    RETURN chr(floor(random() * 95)::int + 32);
    ELSE
		    RETURN chr(floor(random() * 95)::int + 32) || random_text(num - 1);
		END IF;
END
$$ LANGUAGE plpgsql;
