-- Importação do shape de VN de 1965/89 para o BD usando shp2pgsql

-- Corrigindo geometrias invalidas
update fa_model.input_sp_vegnativa_1965e1989_ibge
set geom = ST_MakeValid(geom);

-- Iniciando os processamentos

-- Identificando feições com auto-sobreposição e retornando apenas os polígonos
drop table if exists fa_model.art68_mapa_vegnativa_proc0;
create table fa_model.art68_mapa_vegnativa_proc0 as
	select a.gid,
		a.classe1965,
		a.classe1989,
		ST_CollectionExtract(ST_MakeValid(ST_Difference(a.geom, b.geom)),3) as geom
from fa_model.input_sp_vegnativa_1965e1989_ibge as a
join fa_model.input_sp_vegnativa_1965e1989_ibge as b
on a.gid > b.gid and ST_Intersects(a.geom, b.geom) and not ST_Touches(a.geom, b.geom);

-- Excluindo o resultado anterior das feições originais
drop table if exists fa_model.art68_mapa_vegnativa_proc1;
create table fa_model.art68_mapa_vegnativa_proc1 as
	select a.gid,
		a.classe1965,
		a.classe1989,
		a.geom
from fa_model.input_sp_vegnativa_1965e1989_ibge as a
left join fa_model.art68_mapa_vegnativa_proc0 as b
on a.gid = b.gid
where b.gid is null;

-- Consolidando a tabela sem sobreposições (combinando proc 0 e proc 1)
drop table if exists fa_model.art68_mapa_vegnativa_proc2;
create table fa_model.art68_mapa_vegnativa_proc2 as
	select *
from fa_model.art68_mapa_vegnativa_proc0
union
	select *
from fa_model.art68_mapa_vegnativa_proc1;


-- This block was run with paralalel processing
--0..7 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_includingbiomes.sql"}
--0..7 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_includingfitofisionomias.sql"}

-- select :var_proc num_proc;
-- insert into fa_model.art68_mapa_vegnativa_proc3
-- 	select
-- 		a.gid,
-- 		a.classe1965,
-- 		a.classe1989,
-- 		b.sigla as bioma,
-- 		case when
-- 			ST_Contains(b.geom, a.geom) then a.geom
-- 			else ST_Intersection(ST_Buffer(a.geom, 0.001), ST_Buffer(b.geom, 0.001))
-- 			end as geom			
-- 	from fa_model.art68_mapa_vegnativa_proc2 as a
-- 	left join fa_model.input_biomas_5000_2015 as b
-- 	on ST_Intersects(a.geom, b.geom) and not ST_Touches(a.geom, b.geom)
-- 	where (a.gid % 8) = :var_proc;

-- select :var_proc num_proc;
-- insert into fa_model.art68_mapa_vegnativa_proc4
-- 	select
-- 		a.gid,
-- 		a.classe1965,
-- 		a.classe1989,
-- 		a.bioma,
-- 		b.vn_sgl as fito,
-- 		case when
-- 			ST_Contains(b.geom, a.geom) then a.geom
-- 			else ST_CollectionExtract(ST_MakeValid(ST_Intersection(ST_Buffer(a.geom, 0.001), ST_Buffer(b.geom, 0.001))),3)
-- 			end as geom
-- 		from fa_model.art68_mapa_vegnativa_proc3 as a
-- 		left join fa_model.input_sp_fitofisionomias_radam as b
-- 		on ST_Intersects(a.geom, b.geom) and not ST_Touches(a.geom, b.geom)
-- 		where (a.gid % 8) = :var_proc;
		
drop table if exists fa_model.art68_mapa_vegnativa_proc5;
create table fa_model.art68_mapa_vegnativa_proc5 as
	1965::int as combo_1965all,
	case when bioma = 'AF' then '1965'
		 when bioma = 'CE' then '1989'
		 else 'ERROR'
	end as combo_bioma,
	case when fito in ('CT_SVsvFLest','CT_SVsvFLomb','FLest','FLomb','FOpio','SVfl')
			then '1965'
		 when fito in ('SVab','SVgl','SVsv')
		 	then '1989'
		 when fito in ('MAgua')
		 	then Null
		 else 'ERROR'
	end as combo_radam_final,
	case when fito in ('FLest','FLomb','FOpio','SVfl')
			then '1965'
		 when fito in ('CT_SVsvFLest','CT_SVsvFLomb','SVab','SVgl','SVsv')
		 	then '1989'
		 when fito in ('MAgua')
		 	then Null
		 else 'ERROR'
	end as combo_radam_ct89,
	case when fito in ('CT_SVsvFLest','CT_SVsvFLomb','FLest','FLomb','FOpio','SVfl','SVsv')
			then '1965'
		 when fito in ('SVab','SVgl')
		 	then '1989'
		 when fito in ('MAgua')
		 	then Null
		 else 'ERROR'
	end as combo_radam_sv65,
	case when classe1965 = 'MATA' then '1965'
		 when classe1965 = 'CERRADO' then '1989'
		 else 'ERROR'
	end as combo_cartas65
from fa_model.art68_mapa_vegnativa_proc4;



select distinct classe1965, classe1989, bioma, fito,
	sum(
		case when ST_Area(geom) is null then 0
			else ST_Area(geom) / 10000
		end) as area,
		count(*)
from fa_model.art68_mapa_vegnativa_proc4 
group by classe1965, classe1989, bioma, fito