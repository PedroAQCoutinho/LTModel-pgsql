CREATE TABLE recorte.result3 AS
SELECT *
FROM recorte.result2

CREATE INDEX gix_result3 ON recorte.result3 USING GIST (geom);

ALTER TABLE recorte.result3
ADD CONSTRAINT pk_result3 PRIMARY KEY (gid);

CREATE INDEX gix_result3 ON recorte.result3 USING GIST (geom);

CREATE INDEX ix_result3_1 ON recorte.result3 USING BTREE (cd_mun);

ALTER TABLE recorte.result3
ADD COLUMN cd_biome INT REFERENCES data.bioma_ibge (id);

CREATE INDEX ix_result3_2 ON recorte.result3 USING BTREE (cd_biome);


UPDATE recorte.result3 b
SET cd_biome = c.id
FROM public.pa_br_biomas_2015_ibge_albers a
JOIN data.bioma_ibge c ON a."BIOMA" ILIKE c.nom_bioma
WHERE ST_Within(b.geom, a.geom);


UPDATE recorte.result3 a
SET cd_biome = b.id
    FROM (
    SELECT DISTINCT (gid) gid, c.id, ST_Area(ST_Intersection(a.geom, b.geom)) area2
        FROM recorte.result3 a
                JOIN PUBLIC.pa_br_biomas_2015_ibge_albers b ON ST_Intersects(a.geom, b.geom)
                JOIN data.bioma_ibge c ON b."BIOMA" ILIKE c.nom_bioma
        WHERE a.cd_biome IS NULL
        ORDER BY gid, area2 DESC) b
    WHERE a.gid = b.gid;


UPDATE recorte.result3 b
SET cd_mun = a.cd_mun
FROM public.pa_br_municipios_250_2015_ibge_albers a
WHERE ST_Within(b.geom, a.geom);


UPDATE recorte.result3 a
SET cd_mun = b.cd_mun
    FROM (
    SELECT DISTINCT (gid) gid, b.cd_mun, ST_Area(ST_Intersection(a.geom, b.geom)) area2
        FROM recorte.result3 a
                JOIN public.pa_br_municipios_250_2015_ibge_albers b ON ST_Intersects(a.geom, b.geom)
        WHERE a.cd_mun IS NULL
        ORDER BY gid, area2 DESC) b
    WHERE a.gid = b.gid;


