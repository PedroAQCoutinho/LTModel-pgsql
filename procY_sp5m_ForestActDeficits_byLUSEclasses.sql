-- IBGE RUN
drop table if exists fa_model.sp5m_result_fbdsfull_2
create table fa_model.sp5m_result_fbdsfull_2 as
select
    a.prim_key as prim_key,
    sum(case
            when a.luse_class = 'Class30' then a.area_ha::numeric
            else 0
        end) as agua,
    sum(case
            when a.luse_class = 'Class40' then a.area_ha::numeric
            else 0
        end) as antropizado,
    sum(case
            when a.luse_class = 'Class50' then a.area_ha::numeric
            else 0
        end) as urbano,
    sum(case
            when a.luse_class = 'Class60' then a.area_ha::numeric
            else 0
        end) as cana,
    sum(case
            when a.luse_class = 'Class80' then a.area_ha::numeric
            else 0
        end) as nv_floresta,
    sum(case
            when a.luse_class = 'Class90' then a.area_ha::numeric
            else 0
        end) as nv_naofloresta,
    sum(case
            when a.luse_class = 'Class10' then a.area_ha::numeric
            else 0
        end) as pastagem,
        sum(case
            when a.luse_class = 'Class11' then a.area_ha::numeric
            else 0
        end) as silvicultura,
    sum(case
            when a.luse_class = 'Class14' then a.area_ha::numeric
            else 0
        end) as soja,
    sum(case
            when a.luse_class = 'Class15' then a.area_ha::numeric
            else 0
        end) as transporte        
from fa_model.sp5m_result_fbdsfull as a
group by a.prim_key;

drop table if exists fa_model.sp5m_result_fbdsfull_3;
create table fa_model.sp5m_result_fbdsfull_3 as 
	select
		a.prim_key as prim_key,
		a.agua + a.urbano + a.transporte as noprocess,
		a.antropizado as outros_usos,
		a.cana as cana,
		a.nv_floresta + a.nv_naofloresta as veg_natural,
		a.pastagem as pastagem,
		a.silvicultura as silvicultura,
		a.soja as soja,
		(a.antropizado + a.cana + a.pastagem
		+ a.silvicultura + a.soja) as areautil,
		(a.agua + a.antropizado + a.urbano + a.cana + a.nv_floresta +
		a.nv_naofloresta + a.pastagem + a.silvicultura +
		a.soja + a.transporte) as areatotal
	from fa_model.sp5m_result_fbdsfull_2 as a

-- Rodando com os números da FBDS
create table fa_model.sp5m_result_fbdsfull_4 as
select
	a.prim_key as prim_key,
	(a.cana / a.areautil) * b.app_deficit as cana_app_def,
	(a.cana / a.areautil) * b.lr_deficit as cana_lr_def,
	(a.cana / a.areautil) * (b.app_deficit + b.lr_deficit) as cana_tot_def,
	(a.soja / a.areautil) * b.app_deficit as soja_app_def,
	(a.soja / a.areautil) * b.lr_deficit as soja_lr_def,
	(a.soja / a.areautil) * (b.app_deficit + b.lr_deficit) as soja_tot_def,
	(a.pastagem / a.areautil) * b.app_deficit as pasto_app_def,
	(a.pastagem / a.areautil) * b.lr_deficit as pasto_lr_def,
	(a.pastagem / a.areautil) * (b.app_deficit + b.lr_deficit) as pasto_tot_def,
	(a.silvicultura / a.areautil) * b.app_deficit as silvi_app_def,
	(a.silvicultura / a.areautil) * b.lr_deficit as silvi_lr_def,
	(a.silvicultura / a.areautil) * (b.app_deficit + b.lr_deficit) as silvi_tot_def,
	(a.outros_usos / a.areautil) * b.app_deficit as outros_app_def,
	(a.outros_usos / a.areautil) * b.lr_deficit as outros_lr_def,
	(a.outros_usos / a.areautil) * (b.app_deficit + b.lr_deficit) as outros_tot_def
from fa_model.sp5m_result_fbdsfull_3 as a
join fa_model.sp5m_result_fbds_processed as b
on a.prim_key = b.prim_key
where a.areautil > 0


-- Rodando com os números do IBGE
create table fa_model.sp5m_result_fbdsfull_4_ibge as
select
	a.prim_key as prim_key,
	(a.cana / a.areautil) * b.app_deficit as cana_app_def,
	(a.cana / a.areautil) * b.lr_deficit as cana_lr_def,
	(a.cana / a.areautil) * (b.app_deficit + b.lr_deficit) as cana_tot_def,
	(a.soja / a.areautil) * b.app_deficit as soja_app_def,
	(a.soja / a.areautil) * b.lr_deficit as soja_lr_def,
	(a.soja / a.areautil) * (b.app_deficit + b.lr_deficit) as soja_tot_def,
	(a.pastagem / a.areautil) * b.app_deficit as pasto_app_def,
	(a.pastagem / a.areautil) * b.lr_deficit as pasto_lr_def,
	(a.pastagem / a.areautil) * (b.app_deficit + b.lr_deficit) as pasto_tot_def,
	(a.silvicultura / a.areautil) * b.app_deficit as silvi_app_def,
	(a.silvicultura / a.areautil) * b.lr_deficit as silvi_lr_def,
	(a.silvicultura / a.areautil) * (b.app_deficit + b.lr_deficit) as silvi_tot_def,
	(a.outros_usos / a.areautil) * b.app_deficit as outros_app_def,
	(a.outros_usos / a.areautil) * b.lr_deficit as outros_lr_def,
	(a.outros_usos / a.areautil) * (b.app_deficit + b.lr_deficit) as outros_tot_def
from fa_model.sp5m_result_fbdsfull_3 as a
join fa_model.sp5m_result_ibge_processed as b
on a.prim_key = b.prim_key
where a.areautil > 0

----------
-- Consulta com número da FBDS
select
	sum(cana_def) as cana_def,
	sum(soja_def) as soja_def,
	sum(pasto_def) as pasto_def,
	sum(silvi_def) as silvi_def,
	sum(antrop_def) as outros_def
  from fa_model.sp5m_result_fbdsfull_4;

 -- Consulta com número do IBGE
select
	sum(cana_def) as cana_def,
	sum(soja_def) as soja_def,
	sum(pasto_def) as pasto_def,
	sum(silvi_def) as silvi_def,
	sum(antrop_def) as outros_def
  from fa_model.sp5m_result_fbdsfull_4_ibge;

