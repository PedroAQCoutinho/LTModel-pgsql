INSERT INTO recorte.proc3_04_simulate_single 
            ( 
                        cd_mun, 
                        geom 
            ) 
SELECT cd_mun, 
       (St_dump(geom)).geom 
from   recorte.proc3_03_simulate 
WHERE  (cd_mun % :var_num_proc) = :var_proc;