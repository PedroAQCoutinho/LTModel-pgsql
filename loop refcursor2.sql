DO $$
DECLARE result_table TEXT = 'result';
DECLARE var_input lt_model.inputs;
DECLARE var_table_name TEXT;
DECLARE pcursor REFCURSOR;
DECLARE var_cd_uf INT = 35;
DECLARE var_envelope TEXT = (SELECT ST_AsText(ST_Envelope(ST_Transform(the_geom, 97823))) FROM public.pa_br_limiteestadual_250_2015_ibge WHERE "CD_GEOCUF" = var_cd_uf);
BEGIN
	CLUSTER lt_model.inputs;
	OPEN pcursor FOR SELECT * FROM lt_model.inputs;
	LOOP
		FETCH FROM pcursor INTO var_input;
		EXIT WHEN NOT FOUND;

		var_table_name = LEFT(LOWER(var_input.table_name), 63);
		IF var_input.sub_class = 'CAR' THEN
			PERFORM lt_model.solve_car(var_table_name);
			var_table_name = lt_model.solve_car_table_name(var_table_name);
		END IF;

		IF (SELECT COUNT(*) FROM lt_model.result) > 0 THEN
			IF NOT EXISTS (SELECT table_source FROM lt_model.result WHERE table_source = var_table_name) THEN
				PERFORM lt_model.proc0_insert_all_into_result(var_table_name, var_input, var_envelope);
			END IF;
			PERFORM lt_model.proc0_update_intersection(var_input, var_table_name);
		ELSE
			PERFORM lt_model.proc0_insert_all_into_result(var_table_name, var_input, var_envelope);
		END IF;
		
	END LOOP;
END $$;

