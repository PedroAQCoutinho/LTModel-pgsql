-- Importação do shape de VN de 1965/89 para o BD usando shp2pgsql
-- Importação do shape de VN de 1920 para o BD usando shp2pgsql

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

------------------------------------------------------------------------------------

-- DEFININDO OS COMBOS POR IMOVEL RURAL

-- DEFININDO O BIOMA QUE CADA IMOVEL ESTÁ INSERIDO

	-- Rodou em processamento paralelo
	-- 0..13 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_biomesinfarms_contains.sql"}

	-- Selecionando os imoveis completamente inseridos em um bioma
	-- select :var_proc num_proc;
	-- insert into fa_model.art68_imoveis_proc0
	-- 	select
	-- 		a.gid as prim_key,
	-- 		c.sigla as bioma
	-- 	from fa_model.sp5m_result as a
	-- 	--join fa_model.sp5m_result_fbds_processed as b
	-- 	--on a.gid = b.prim_key
	-- 	left join fa_model.input_biomas_5000_2015 as c
	-- 	on ST_Contains(c.geom, a.geom)
	-- 	where (a.gid % 14) = :var_proc --and b.lr_deficit > 0
	-- 	group by a.gid, c.sigla;

	-- Selecionando os imoveis que estao entre 2 ou mais biomas
	-- 0..13 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_biomesinfarms_intersects.sql"}
	-- select :var_proc num_proc;
	-- insert into fa_model.art68_imoveis_proc1
	-- 	select
	-- 		a.gid as prim_key,
	-- 		c.sigla as bioma,
	-- 		sum(ST_Area(ST_Intersection(a.geom, c.geom))) as area
	-- 	from fa_model.sp5m_result as a
	-- 	--join fa_model.sp5m_result_fbds_processed as b
	-- 	--on a.gid = b.prim_key
	-- 	left join fa_model.input_biomas_5000_2015 as c
	-- 	on ST_Intersects(c.geom, a.geom) and not ST_Contains(c.geom, a.geom)
	-- 	where (a.gid % 14) = :var_proc --and b.lr_deficit > 0
	-- 	group by a.gid, c.sigla;

-- Selecionando o bioma com maior área no imóvel
delete from fa_model.art68_imoveis_proc0
where bioma is null;

delete from fa_model.art68_imoveis_proc1
where bioma is null and area is null;

drop table if exists fa_model.art68_imoveis_proc2;
create table if not exists fa_model.art68_imoveis_proc2 as
	select
		distinct on(a.prim_key)
		a.prim_key,
		a.bioma
	from fa_model.art68_imoveis_proc1 as a
	join fa_model.art68_imoveis_proc1 as b
	on a.prim_key = b.prim_key
	order by a.prim_key, a.area desc;

-- Juntando todos os imoveis
drop table if exists fa_model.art68_imoveis_proc3;
create table if not exists fa_model.art68_imoveis_proc3 as
		select *
	from fa_model.art68_imoveis_proc0
	union
		select *
	from fa_model.art68_imoveis_proc2;

-- Selecionando os imoveis completamente inseridos em uma fitofisionomia
-- 0..13 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_fitosinfarms_contains.sql"}
-- select :var_proc num_proc;
-- insert into fa_model.art68_imoveis_proc4
--     select
--         a.gid as prim_key,
--         c.vn_sgl as fito
--     from fa_model.sp5m_result as a
--     --join fa_model.sp5m_result_fbds_processed as b
--     --on a.gid = b.prim_key
--     left join fa_model.input_sp_fitofisionomias_radam as c
--     on ST_Contains(c.geom, a.geom)
--     where (a.gid % 14) = :var_proc --and b.lr_deficit > 0
--     group by a.gid, c.vn_sgl;

-- Selecionando os imoveis que estao entre 2 ou mais fitofisionomias
-- 0..13 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_fitosinfarms_intersects.sql"}
-- select :var_proc num_proc;
-- insert into fa_model.art68_imoveis_proc5
--     select
--         a.gid as prim_key,
--         c.vn_sgl as fito,
--         sum(ST_Area(ST_Intersection(a.geom, c.geom))) as area
--     from fa_model.sp5m_result as a
--     --join fa_model.sp5m_result_fbds_processed as b
-- 	--on a.gid = b.prim_key
--     left join fa_model.input_sp_fitofisionomias_radam as c
--     on ST_Intersects(c.geom, a.geom) and not ST_Contains(c.geom, a.geom)
--     where (a.gid % 14) = :var_proc --and b.lr_deficit > 0
--     group by a.gid, c.vn_sgl;

-- Selecionando a fitofisionomia com maior área no imóvel
delete from fa_model.art68_imoveis_proc4
where fito is null;

delete from fa_model.art68_imoveis_proc5
where fito is null and area is null;

drop table if exists fa_model.art68_imoveis_proc6;
create table if not exists fa_model.art68_imoveis_proc6 as
	select
		distinct on(a.prim_key)
		a.prim_key,
		a.fito
	from fa_model.art68_imoveis_proc5 as a
	join fa_model.art68_imoveis_proc5 as b
	on a.prim_key = b.prim_key
	order by a.prim_key, a.area desc;

-- Juntando todos os imoveis 
drop table if exists fa_model.art68_imoveis_proc7;
create table if not exists fa_model.art68_imoveis_proc7 as
		select *
	from fa_model.art68_imoveis_proc4
	union
		select *
	from fa_model.art68_imoveis_proc6;

-- Unindo biomas (proc3) e fitofisionomias (proc7) por imóvel
drop table if exists fa_model.art68_imoveis_proc8;
create table if not exists fa_model.art68_imoveis_proc8 as
	select
		distinct on(a.prim_key)
		a.prim_key,
		a.bioma,
		b.fito
	from fa_model.art68_imoveis_proc3 as a
	join fa_model.art68_imoveis_proc7 as b
	on a.prim_key = b.prim_key
	order by a.prim_key, a.bioma, b.fito asc

-- Calculando a vegetação nativa nos imóveis rurais
-- 0..13 | foreach {start cmd "/k psql -U postgres -d atlas -h geonode -v var_proc=$_ -a -f art68_areaofvn6589infarms.sql"}
-- select :var_proc num_proc;
-- insert into fa_model.art68_imoveis_proc9
-- 	select
-- 		a.gid as prim_key,
-- 		case when c.classe1965 = 'CERRADO' and c.classe1989 is null then
-- 				sum(ST_Area(ST_Intersection(ST_Buffer(a.geom, 0.001), ST_Buffer(c.geom, 0.001)))) / 10000
-- 			 else 0
-- 		end as cedesm6589_ha,
-- 		case when c.classe1965 = 'CERRADO' and c.classe1989 = 'CERRADO' then
-- 				sum(ST_Area(ST_Intersection(ST_Buffer(a.geom, 0.001), ST_Buffer(c.geom, 0.001)))) / 10000
-- 			 else 0
-- 		end as cerema6589_ha,
-- 		case when c.classe1965 = 'MATA' and c.classe1989 = 'CERRADO' then
-- 				sum(ST_Area(ST_Intersection(ST_Buffer(a.geom, 0.001), ST_Buffer(c.geom, 0.001)))) / 10000
-- 			 else 0
-- 		end as marema6589_ha,
-- 		case when c.classe1965 = 'MATA' and c.classe1989 is null then
-- 				sum(ST_Area(ST_Intersection(ST_Buffer(a.geom, 0.001), ST_Buffer(c.geom, 0.001)))) / 10000
-- 			 else 0
-- 		end as manull6589_ha
-- 	from fa_model.sp5m_result as a
-- 	--join fa_model.sp5m_result_fbds_processed as b
-- 	--on a.gid = b.prim_key
-- 	left join fa_model.art68_mapa_vegnativa_proc4 as c
-- 	on ST_Intersects(c.geom, a.geom) and not ST_Touches(c.geom, a.geom)
-- 	where (a.gid % 14) = :var_proc -- and b.lr_deficit > 0
-- 	group by a.gid

-- Limpando duplicatas do proc9
-- PRECISA VER SE FICA COM A REFATORAÇÃO QUE FOI FEITA
drop table if exists fa_model.art68_imoveis_proc10;
create table if not exists fa_model.art68_imoveis_proc10 as
	select
		prim_key,
		sum(cedesm6589_ha) as cedesm6589_ha,
		sum(cerema6589_ha) as cerema6589_ha,
		sum(marema6589_ha) as marema6589_ha,
		sum(manull6589_ha) as manull6589_ha
	from fa_model.art68_imoveis_proc9
	group by prim_key

-- Criando tabela de referencia para estimativa do art68
drop table if exists fa_model.art68_imoveis_proc11;
create table if not exists fa_model.art68_imoveis_proc11 as
	select
		a.prim_key,
		a.bioma,
		a.fito,
		case when b.cedesm6589_ha + b.cerema6589_ha >= b.marema6589_ha + b.manull6589_ha
				then 'CERRADO'
			 else 'MATA'
		end as carta_ibge,
		c.areaproc + c.noprocess as area_imovel,
		--TODO: tirar as divisões por 10000 pq já refatorei proc9 incluindo isso
		(b.cedesm6589_ha + b.cerema6589_ha + b.marema6589_ha + b.manull6589_ha) / 10000 as vn65,
		(b.cerema6589_ha + b.marema6589_ha + b.manull6589_ha) / 10000 as vn89r,
		(b.cerema6589_ha + b.marema6589_ha) / 10000 as vn89d,
		c.eq_co_nv + c.eq_coapp_nv as vn08,
		c.lr_deficit as def08
	from fa_model.art68_imoveis_proc8 as a
	join fa_model.art68_imoveis_proc10 as b
	on a.prim_key = b.prim_key
	right join fa_model.sp5m_result_fbds_processed as c
	-- right join pq o *fbds_processed é diferente do sp5m_result, em função da conversão dos imóveis pra
	-- raster pra extrair o uso do solo. Isso deve ser corrigido com a malha full do estado
	-- e td rodando no PGSQL
	on a.prim_key = c.prim_key
	where lr_deficit > 0;

-- Regras de decisão para avaliacao dos passivos
drop table if exists fa_model.art68_imoveis_proc12;
create table if not exists fa_model.art68_imoveis_proc12 as
	select
		a.prim_key,
		a.def08,
		case when a.vn65 >= a.area_imovel * 0.2
				then a.def08
			 else 
			 	case when a.vn65 - a.vn08 < 0 then 0
				 	 else a.vn65 - a.vn08
				end
		end as def_combo_1965all,
		case when a.carta_ibge = 'MATA' then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.carta_ibge = 'CERRADO' then
				case when a.vn89d >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn89d - a.vn08 < 0 then 0
				 	 		 else a.vn89d - a.vn08
						end
				end
		end as def_combo_carta_d,
		case when a.carta_ibge = 'MATA' then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.carta_ibge = 'CERRADO' then
				case when a.vn89r >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn89r - a.vn08 < 0 then 0
				 	 		 else a.vn89r - a.vn08
						end
				end
		end as def_combo_carta_r,
		case when a.bioma = 'AF' then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.bioma = 'CE' then
				case when a.vn89d >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn89d - a.vn08 < 0 then 0
				 	 		 else a.vn89d - a.vn08
						end
				end
		end as def_combo_bioma_d,
		case when a.bioma = 'AF' then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.bioma = 'CE' then
				case when a.vn89r >= a.area_imovel * 0.2
						then a.def08
					else
						case when a.vn89r - a.vn08 < 0 then 0
				 	 		 else a.vn89r - a.vn08
						end
				end
		end as def_combo_bioma_r,		
		case when a.fito in ('CT_SVsvFLest','CT_SVsvFLomb','FLest','FLomb','FOpio','SVfl') then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.fito in ('SVab','SVgl','SVsv') then
			 	case when a.vn89d >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn89d - a.vn08 < 0 then 0
				 	 		 else a.vn89d - a.vn08
						end
				end
		end as def_combo_radamneutro_d,
		case when a.fito in ('CT_SVsvFLest','CT_SVsvFLomb','FLest','FLomb','FOpio','SVfl') then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.fito in ('SVab','SVgl','SVsv') then
			 	case when a.vn89r >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn89r - a.vn08 < 0 then 0
				 	 		 else a.vn89r - a.vn08
						end
				end
		end as def_combo_radamneutro_r,
		case when a.fito in ('FLest','FLomb','FOpio','SVfl') then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.fito in ('CT_SVsvFLest','CT_SVsvFLomb','SVab','SVgl','SVsv') then
			 	case when a.vn89d >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn89d - a.vn08 < 0 then 0
				 	 		 else a.vn89d - a.vn08
						end
				end
		end as def_combo_radamct89_d,
		case when a.fito in ('FLest','FLomb','FOpio','SVfl') then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.fito in ('CT_SVsvFLest','CT_SVsvFLomb','SVab','SVgl','SVsv') then
			 	case when a.vn89r >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn89r - a.vn08 < 0 then 0
				 	 		 else a.vn89r - a.vn08
						end
				end
		end as def_combo_radamct89_r,
		case when a.fito in ('CT_SVsvFLest','CT_SVsvFLomb','FLest','FLomb','FOpio','SVfl','SVsv') then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.fito in ('SVab','SVgl') then
			 	case when a.vn89d >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn89d - a.vn08 < 0 then 0
				 	 		 else a.vn89d - a.vn08
						end
				end
		end as def_combo_radamsv65_d,
		case when a.fito in ('CT_SVsvFLest','CT_SVsvFLomb','FLest','FLomb','FOpio','SVfl','SVsv') then
				case when a.vn65 >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn65 - a.vn08 < 0 then 0
				 	 		 else a.vn65 - a.vn08
						end
				end
			 when a.fito in ('SVab','SVgl') then
			 	case when a.vn89r >= a.area_imovel * 0.2
						then a.def08
					 else
						case when a.vn89r - a.vn08 < 0 then 0
				 	 		 else a.vn89r - a.vn08
						end
				end
		end as def_combo_radamsv65_r	

	from fa_model.art68_imoveis_proc11 as a;
		





select distinct classe1965, classe1989, bioma, fito,
	sum(
		case when ST_Area(geom) is null then 0
			else ST_Area(geom) / 10000
		end) as area,
		count(*)
from fa_model.art68_mapa_vegnativa_proc4 
group by classe1965, classe1989, bioma, fito

SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state='active' AND query LIKE 'insert into fa_model%'


-- Criando os mapas de VN reclassificados para cada combo
-- drop table if exists fa_model.art68_combo_1965all;
-- create table if not exists fa_model.art68_combo_1965all as
-- 	select
-- 		case when b.combo_1965all not in ('ERRO1', 'ERRO2')
-- 			then ST_Union(geom)
-- 		end as geom
-- 	from fa_model.art68_mapa_vegnativa_proc4 as a
-- 	join fa_model.art68_mapa_vegnativa_proc5 as b
-- 	on a.gid = b.gid
-- 	group by b.combo_1965all;

-- drop table if exists fa_model.art68_combo_bioma;
-- create table if not exists fa_model.art68_combo_bioma as
-- 	select
-- 		case when b.combo_1965all not in ('ERRO1', 'ERRO2')
-- 			then ST_Union(geom)
-- 		end as geom
-- 	from fa_model.art68_mapa_vegnativa_proc4 as a
-- 	join fa_model.art68_mapa_vegnativa_proc5 as b
-- 	on a.gid = b.gid
-- 	group by b.combo_1965all;



