--------------------------------------------------------
-- INSERTING THE IBGE CODE FOR EACH RURAL PROPERTY

-- Case when property is totally within one municipality
SELECT :var_proc num_proc;
INSERT INTO lt_model.result_cdmun (gid, cd_mun_contain, cd_mun)
	SELECT
    a.gid,
    TRUE,
		b.cd_mun
	FROM lt_model.result AS a
	JOIN lt_model.aux_pa_br_municipios_5570 AS b
		ON ST_CoveredBy(a.geom, b.geom)
	WHERE (a.gid % :threads) = :var_proc;

-- Case when property is between two or more municipalities
SELECT :var_proc num_proc;
INSERT INTO lt_model.result_cdmun (gid, cd_mun_contain, cd_mun)
	SELECT DISTINCT ON (sub.id_imovel)
     sub.id_imovel,
     FALSE,
     sub.cd_mun
	FROM(
		SELECT
			a.gid AS id_imovel,
			b.cd_mun,
     SUM(ST_Area(ST_Intersection(ST_MakeValid(ST_Buffer(a.geom,0.001)),ST_MakeValid(ST_Buffer(b.geom,0.001))))) AS area_muns
		FROM lt_model.result AS a
	JOIN lt_model.aux_pa_br_municipios_5570 AS b
			ON ST_Intersects(a.geom, b.geom) AND NOT ST_CoveredBy(a.geom, b.geom)
		GROUP BY a.gid,b.cd_mun) AS sub
	WHERE (sub.id_imovel % :threads) = :var_proc
	ORDER BY sub.id_imovel, sub.area_muns DESC;
