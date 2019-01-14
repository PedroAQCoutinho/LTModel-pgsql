CREATE OR REPLACE FUNCTION lt_model.trycatch_topology(geom_a geometry, geom_b geometry)
RETURNS void AS 
$$
BEGIN
  SELECT ST_Intersection(geom_a, geom_b); 
  EXCEPTION WHEN OTHERS THEN
	INSERT INTO lt_model.topology_log(error) VALUES (SQLERRM);
END;
$$
LANGUAGE plpgsql;