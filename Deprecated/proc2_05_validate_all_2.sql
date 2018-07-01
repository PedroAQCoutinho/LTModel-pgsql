INSERT INTO lt_model.result2
SELECT gid, table_source, ownership_class, sub_class, area_original, 
       original_gid, ST_Multi(ST_CollectionExtract(ST_MakeValid(geom), 3))::geometry('MultiPolygon', 97823) geom, area, ag_area_loss, aru_area_loss, carpo_area_loss, 
       carpr_area_loss, com_area_loss, ml_area_loss, nd_area_loss, ql_area_loss, 
       sigef_area_loss, ti_area_loss, tlpc_area_loss, tlpl_area_loss, 
       trans_area_loss, ucpi_area_loss, ucus_area_loss, urb_area_loss, 
       cd_mun_2006
  FROM lt_model.result
  WHERE (gid % :var_num_proc) = :var_proc;