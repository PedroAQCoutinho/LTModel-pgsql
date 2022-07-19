DO $$
DECLARE result_table TEXT = 'result';
DECLARE var_input recorte.inputs;
DECLARE var_table_name TEXT;
DECLARE pcursor REFCURSOR;
DECLARE var_cd_uf INT = 35;
DECLARE var_envelope TEXT = (SELECT ST_AsText(ST_Envelope(ST_Transform(the_geom, 97823))) FROM public.pa_br_limiteestadual_250_2015_ibge WHERE "CD_GEOCUF" = var_cd_uf);
BEGIN
	CLUSTER recorte.inputs;
	OPEN pcursor FOR SELECT * FROM recorte.inputs;
	LOOP
		FETCH FROM pcursor INTO var_input;
		EXIT WHEN NOT FOUND;

		var_table_name = LEFT(LOWER(var_input.table_name), 63);
		IF var_input.sub_class = 'CAR' THEN
			PERFORM recorte.solve_car(var_table_name);
			var_table_name = recorte.solve_car_table_name(var_table_name);
		END IF;

		IF (SELECT COUNT(*) FROM recorte.result) > 0 THEN
			IF NOT EXISTS (SELECT table_source FROM recorte.result WHERE table_source = var_table_name) THEN
				PERFORM recorte.proc0_insert_all_into_result(var_table_name, var_input, var_envelope);
			END IF;
			PERFORM recorte.proc0_update_intersection(var_input, var_table_name);
		ELSE
			PERFORM recorte.proc0_insert_all_into_result(var_table_name, var_input, var_envelope);
		END IF;
		
	END LOOP;
END $$;

