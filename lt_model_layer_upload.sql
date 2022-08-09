ogr2ogr -sql "SELECT CD_UFi cd_uf, geometry from pa_br_limiteEstadual_250_2015_ibge" pa_br_limiteEstadual_250_2015_ibge.shp lt_model.aux_pa_br_estados




ogr2ogr -f "ESRI Shapefile" -sql "SELECT quadkey, ST_Centroid(geom) geom from apq" apq_centroids.shp apq.shp