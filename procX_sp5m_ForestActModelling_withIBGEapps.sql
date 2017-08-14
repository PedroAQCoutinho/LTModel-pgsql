-- IBGE RUN

-- Extracting the values of natural vegetation
drop table if exists fa_model.sp5m_result_ibge_2;
create table fa_model.sp5m_result_ibge_2 as
select
    a.prim_key as prim_key,
    sum(case
            when a.luse_class = 'Class15' then a.area_ha::numeric
            else 0
        end) as noprocess,
    sum(case
            when a.luse_class = 'Class40' then a.area_ha::numeric
            else 0
        end) as eq_co_at,
    sum(case
            when a.luse_class = 'Class41' then a.area_ha::numeric
            else 0
        end) as eq_coapp1_at,
    sum(case
            when a.luse_class = 'Class42' then a.area_ha::numeric
            else 0
        end) as eq_coapp2_at,
    sum(case
            when a.luse_class = 'Class80' then a.area_ha::numeric
            else 0
        end) as eq_co_nv,
    sum(case
            when a.luse_class = 'Class81' then a.area_ha::numeric
            else 0
        end) as eq_coapp1_nv,
    sum(case
            when a.luse_class = 'Class82' then a.area_ha::numeric
            else 0
        end) as eq_coapp2_nv
from fa_model.sp5m_result_ibge as a
group by a.prim_key;

alter table fa_model.sp5m_result_ibge_2
add column areaproc numeric;

update fa_model.sp5m_result_ibge_2
set areaproc = eq_co_at + eq_coapp1_at + eq_coapp2_at + eq_co_nv + eq_coapp1_nv + eq_coapp2_nv;

----------
drop table if exists fa_model.sp5m_result_ibge_proc0;
create table if not exists fa_model.sp5m_result_ibge_proc0 as
    select
        a.gid as prim_key,
        a.cd_mun_2006 as ibgecode,
        'C'::text as biome, --trocar para "b.biome" depois
        'B'::text as vegtype_la, --trocar para "b.vegtype_la" depois
        c.areaproc as areaproc,
        c.noprocess as noprocess,
        b.mf_ha as mf_incra,
        c.areaproc / b.mf_ha as tot_mf,
        c.eq_co_at as eq_co_at,
        c.eq_co_nv as eq_co_nv,
        c.eq_coapp1_at as eq_coapp1_at,
        c.eq_coapp1_nv as eq_coapp1_nv,
        c.eq_coapp2_at as eq_coapp2_at,
        c.eq_coapp2_nv as eq_coapp2_nv
    from fa_model.sp5m_result as a
    left join fa_model.input_mf_incra_5570 as b
    on a.cd_mun_2006 = b.cd_mun
    join fa_model.sp5m_result_ibge_2 as c
    on a.gid = c.prim_key;

-----------
drop table if exists fa_model.sp5m_result_ibge_proc1;
create table fa_model.sp5m_result_ibge_proc1 as
    select
        a.prim_key,
        a.ibgecode,
        a.biome,
        a.vegtype_la,
        
        case when b.sub_class in ('AG', 'TRANS', 'URB') then 'NP'
             else b.sub_class
        end as land_tenure,
        b.ownership_class as pl_pc_np,

        case when b.sub_class in ('AG', 'TRANS', 'URB', 'RES') then 'NP'
             when b.sub_class in ('UCUS', 'UCPI', 'ML', 'TI') then 'PC'
             when b.sub_class in ('SIGEF', 'CARpr','CARpo', 'SI') then 'PL'
             when b.sub_class in ('QL', 'ARU', 'COM', 'TLPL') then 'PL1'
             when b.sub_class in ('TLPC') then 'ND1'
             when b.sub_class in ('ND') then 'ND'
        end as land_destination,

        case when b.ownership_class = 'PL' then
                case when a.tot_mf <= 4 then 'FF'
                     else 'nFF'
                end 
             when b.ownership_class = 'PC' and b.sub_class in ('TLPC') then
                case when ((a.eq_coapp1_nv + a.eq_coapp2_nv + a.eq_co_nv) / a.areaproc) >=0.95 then 'TLPC'
                     when a.tot_mf <= 4 then 'TLFF'
                     else 'TLnFF'
                end
             else b.ownership_class 
        end as ownership_classes,

        a.areaproc,
        a.noprocess,
        a.mf_incra,
        a.tot_mf,
        a.eq_co_at,
        a.eq_co_nv,
        a.eq_coapp1_at,
        a.eq_coapp1_nv,
        a.eq_coapp2_at,
        a.eq_coapp2_nv
    from fa_model.sp5m_result_ibge_proc0 as a
    join fa_model.sp5m_result as b
    on a.prim_key = b.gid;
    
------------
drop table if exists fa_model.sp5m_result_ibge_proc2;
create table fa_model.sp5m_result_ibge_proc2 as
	select 
		a.prim_key as prim_key,
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
		when a.ownership_classes in ('nFF', 'FF', 'TLnFF', 'TLFF') then
             case when a.vegtype_la = 'F' then a.areaproc*0.8
		          when a.vegtype_la = 'C' then a.areaproc*0.35
                  --when a.vegtype_la = 'B' and a.biome = 'C' and c.nm_uf = 'PI' then a.areaproc*0.3  --TODO PIAUI 30% para Cerrado
		          else a.areaproc*0.2
             end
        end as lr_required
	from fa_model.sp5m_result_ibge_proc1 as a;

----------
drop table if exists fa_model.temp_sp5m_result_ibge_proc3a;
create table fa_model.temp_sp5m_result_ibge_proc3a as
    select
        a.prim_key as prim_key,
        case when a.ownership_classes in ('nFF', 'FF', 'TLnFF', 'TLFF') then
             case when a.tot_mf <= 1 then 0.16667
                  when a.tot_mf <= 2 then 0.26667
                  when a.tot_mf <= 4 then 0.5
                  when a.tot_mf <= 10 then 0.66667
                  when a.tot_mf > 10 then 1
             end * a.eq_coapp1_at
        else 0
        end as eq_coapp1_ate,
        case when a.ownership_classes in ('nFF', 'FF', 'TLnFF', 'TLFF') then
             case when a.tot_mf <= 1 then 0.16667
                  when a.tot_mf <= 2 then 0.26667
                  when a.tot_mf <= 4 then 0.5
                  when a.tot_mf <= 10 then 0.66667
                  when a.tot_mf > 10 then 1
             end * a.eq_coapp1_nv
        else 0
        end as eq_coapp1_nve,
        a.eq_coapp2_at * 0.3 as eq_coapp2_ate,
        a.eq_coapp2_nv * 0.3 as eq_coapp2_nve
    from fa_model.sp5m_result_ibge_proc1 as a;

---------------

drop table if exists fa_model.temp_sp5m_result_ibge_proc3b;
create table fa_model.temp_sp5m_result_ibge_proc3b as
    select
        a.prim_key as prim_key,
        a.eq_coapp1_at + a.eq_coapp2_at + a.eq_coapp1_nv + a.eq_coapp2_nv as app_required, 
        a.eq_coapp1_at + a.eq_coapp2_at as eq_coapp_at,
        a.eq_coapp1_nv + a.eq_coapp2_nv as eq_coapp_nv,
        b.eq_coapp1_ate + b.eq_coapp2_ate as eq_coapp_ate,
        b.eq_coapp1_nve + b.eq_coapp2_nve as eq_coapp_nve
    from fa_model.sp5m_result_ibge_proc1 as a
    join fa_model.temp_sp5m_result_ibge_proc3a as b
    on a.prim_key = b.prim_key;

------------------
drop table if exists fa_model.temp_sp5m_result_ibge_proc3c;
create table fa_model.temp_sp5m_result_ibge_proc3c as
    select
        a.prim_key as prim_key,        
        case when a.ownership_classes in ('nFF', 'FF', 'TLnFF', 'TLFF') then
             case when b.eq_coapp_nv >= b.eq_coapp_ate + b.eq_coapp_nve
                       then b.eq_coapp_at
                  else b.app_required - (b.eq_coapp_ate + b.eq_coapp_nve)
             end
             else 0
        end as rart61
    from fa_model.sp5m_result_ibge_proc1 as a                  
    join fa_model.temp_sp5m_result_ibge_proc3b as b
    on a.prim_key = b.prim_key;

---------------------
drop table if exists fa_model.temp_sp5m_result_ibge_proc3d;
create table fa_model.temp_sp5m_result_ibge_proc3d as
    select
        a.prim_key as prim_key,
        b.app_required - c.rart61 as app_needed,
        case when a.ownership_classes in ('nFF', 'FF', 'TLnFF', 'TLFF') 
                  and b.eq_coapp_nv < b.eq_coapp_ate + b.eq_coapp_nve
                  then (b.app_required - c.rart61) - b.eq_coapp_nve
             else 0
        end as app_deficit         
    from fa_model.sp5m_result_ibge_proc1 as a
    join fa_model.temp_sp5m_result_ibge_proc3b as b
    on a.prim_key = b.prim_key
    join fa_model.temp_sp5m_result_ibge_proc3c as c
    on a.prim_key = c.prim_key;

 ------------------
drop table if exists fa_model.sp5m_result_ibge_proc3;
create table fa_model.sp5m_result_ibge_proc3 as 
    select
        b.prim_key as prim_key,
        b.app_required as app_required,
        b.eq_coapp_at as eq_coapp_at,
        b.eq_coapp_nv as eq_coapp_nv,
        b.eq_coapp_ate as eq_coapp_ate,
        b.eq_coapp_nve as eq_coapp_nve,
        c.rart61 as rart61,
        d.app_needed as app_needed,
        d.app_deficit as app_deficit
from fa_model.temp_sp5m_result_ibge_proc3b as b
join fa_model.temp_sp5m_result_ibge_proc3c as c
on b.prim_key = c.prim_key
join fa_model.temp_sp5m_result_ibge_proc3d as d
on b.prim_key = d.prim_key;

------------------
drop table if exists fa_model.sp5m_result_ibge_proc4;
create table fa_model.sp5m_result_ibge_proc4 as 
	select
		a.prim_key as prim_key,
        
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 when a.ownership_classes in ('FF', 'TLFF') and a.eq_co_nv - b.lr_required < 0 then b.lr_required - a.eq_co_nv
             else 0
        end as rart67,
                    
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
             when a.eq_co_nv - b.lr_required > 0 and a.biome <> 'M' then a.eq_co_nv - b.lr_required
             else 0
        end as not_protected,
		
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 when a.eq_co_nv - b.lr_required > 0 and a.biome = 'M' then a.eq_co_nv - b.lr_required
             else 0
		end as surplus_af,
                    
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 when a.eq_co_nv - b.lr_required > 0 then a.eq_co_nv - b.lr_required
             else 0
        end as tradable_no_lr,
                
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 when a.ownership_classes in ('FF', 'TLFF') then 
                case when a.eq_co_nv - b.lr_required >=0 then b.lr_required
                     else a.eq_co_nv
                end
        else 0
        end as tradable_in_lr,
		
        case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC', 'TLFF', 'FF') then 0
			 when a.vegtype_la <> 'F'
                  and (a.eq_co_nv - b.lr_required) < 0
                  and ((a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate) - b.lr_required) > 0
				  then b.lr_required - a.eq_co_nv
             when a.vegtype_la <> 'F'
				  and ((a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate) - b.lr_required) <= 0
                  then c.eq_coapp_nv + c.eq_coapp_ate
             when a.vegtype_la = 'F' 
				  and (a.eq_co_nv - a.areaproc * 0.5) < 0
                  and ((a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate) - a.areaproc * 0.5) > 0
                  then a.areaproc * 0.5 - a.eq_co_nv
             when a.vegtype_la = 'F'
                  and ((a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate) - a.areaproc * 0.5) <= 0
                  then c.eq_coapp_nve + c.eq_coapp_ate
             else 0
        end as rart15,
                                
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC', 'TLFF', 'FF') then 0
             when a.vegtype_la = 'F'
                  and (a.eq_co_nv - b.lr_required) < 0
                  and (a.eq_co_nv - a.areaproc * 0.5) > 0
                  then b.lr_required - a.eq_co_nv
             when a.vegtype_la = 'F' 
				  and (a.eq_co_nv - a.areaproc * 0.5) <= 0
                  then a.areaproc * 0.3
             else 0
        end as rart13,
        
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC', 'TLFF', 'FF') then 0
			 when ((a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate) - b.lr_required) < 0 
				  and a.vegtype_la <> 'F'
                  then b.lr_required - (a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate)
             when a.vegtype_la = 'F'
                  and ((a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate) - a.areaproc * 0.5) < 0
                  then a.areaproc * 0.5 - (a.eq_co_nv + c.eq_coapp_nv + c.eq_coapp_ate)
             else 0
             end as lr_deficit
        
	from fa_model.sp5m_result_ibge_proc1 as a
	join fa_model.sp5m_result_ibge_proc2 as b
	on a.prim_key = b.prim_key
	join fa_model.sp5m_result_ibge_proc3 as c
	on a.prim_key = c.prim_key;

-------------------
drop table if exists fa_model.sp5m_result_ibge_proc5;
create table fa_model.sp5m_result_ibge_proc5 as
	select
		a.prim_key as prim_key,
        case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
             else round(a.areaproc - d.surplus_af - b.lr_required - 
                  (c.eq_coapp_nv + c.eq_coapp_at) +
                  (d.rart13 + d.rart15 + d.rart67),4)
             end as pr_noob_noco,
		
        case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 else round(a.eq_co_at + d.not_protected,4)
			 end as pr_noob_fullco,

		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 else round(b.lr_required - (d.rart13 + d.rart15 + d.rart67 + d.lr_deficit),4)
			 end as lr_deficit_amnesty,
        
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
             else round(a.eq_co_nv - d.tradable_no_lr + d.rart13 + d.rart15 + d.rart67 - b.lr_required + d.lr_deficit,4)
             end as consistency_test1,
        
        case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 else round(a.areaproc - b.lr_required - (c.eq_coapp_nv + c.eq_coapp_at) + (d.rart13 + d.rart15 + d.rart67),4) -
                  round(a.eq_co_at + d.tradable_no_lr - d.lr_deficit,4)
                  end as consistency_test2,
            
		case when a.ownership_classes in ('ND', 'NP', 'PC', 'TLPC') then 0
			 else round(a.eq_co_at + d.tradable_no_lr,4) -
                  round(a.areaproc + d.lr_deficit - b.lr_required -
                  (c.eq_coapp_nv + c.eq_coapp_at) + (d.rart13 + d.rart15 + d.rart67),4)
                  end as consistency_test3

	from fa_model.sp5m_result_ibge_proc1 as a
	join fa_model.sp5m_result_ibge_proc2 as b
	on a.prim_key = b.prim_key
	join fa_model.sp5m_result_ibge_proc3 as c
	on a.prim_key = c.prim_key
	join fa_model.sp5m_result_ibge_proc4 as d
	on a.prim_key = d.prim_key;

----------------------------
drop table if exists fa_model.sp5m_result_ibge_processed;
create table fa_model.sp5m_result_ibge_processed as
	select
     a.prim_key as prim_key, 
     a.ibgecode as ibgecode,
     a.biome as biome,
     a.vegtype_la as  vegtype_la,
     a.land_tenure as land_tenure,
     a.land_destination as land_destination,
     a.ownership_classes as ownership_classes,
     a.pl_pc_np as pl_pc_np,
     a.areaproc as areaproc,
     a.noprocess as noprocess,
     a.mf_incra as mf_incra,
     a.tot_mf as tot_mf,
     a.eq_co_at as eq_co_at,
     a.eq_co_nv as eq_co_nv,
     c.eq_coapp_at as eq_coapp_at,
     c.eq_coapp_nv as eq_coapp_nv,
     c.eq_coapp_ate as eq_coapp_ate,
     c.eq_coapp_nve as eq_coapp_nve,
     c.app_required as app_required,
     c.rart61 as rart61,
     c.app_needed as app_needed,
     c.app_deficit as app_deficit,
     b.lr_required as lr_required,
     d.rart13 as rart13,
     d.rart15 as rart15,
     d.rart67 as rart67,
     b.lr_required-(d.rart13+d.rart67+ d.rart15) as lr_needed,
     d.not_protected as not_protected,
     d.surplus_af as surplus_af,
     d.tradable_no_lr as tradable_no_lr,
     d.tradable_in_lr as tradable_in_lr,
     d.lr_deficit as lr_deficit,
     e.pr_noob_noco as pr_noob_noco,
     e.pr_noob_fullco as pr_noob_fullco,
     e.lr_deficit_amnesty as lr_deficit_amnesty,
     case when c.app_deficit > 0 then 1
	else 0
	end as bool_app,
     case when d.lr_deficit > 0 then 1
	else 0
	end as bool_lr,
     case when c.app_deficit > 0 or d.lr_deficit > 0 then 1
	else 0
	end as bool_def

	from fa_model.sp5m_result_ibge_proc1 as a
	join fa_model.sp5m_result_ibge_proc2 as b
	on a.prim_key = b.prim_key
	join fa_model.sp5m_result_ibge_proc3 as c
	on a.prim_key = c.prim_key
	join fa_model.sp5m_result_ibge_proc4 as d
	on a.prim_key = d.prim_key
	join fa_model.sp5m_result_ibge_proc5 as e
	on a.prim_key = e.prim_key;

------------------------------
create view fa_model.sp5m_finalresult as
select
	a.*, b.geom
	from fa_model.sp5m_result_ibge_processed as a
	join fa_model.sp5m_result as b
	on a.prim_key = b.gid

-- Passivo por municipio

copy(
select
	c.cd_mun,
	c.nm_mun,
	sum(a.lr_deficit) as lr_def,
	sum(a.app_deficit) as app_def,
	sum(a.not_protected) as not_prot
	from fa_model.sp5m_result_ibge_processed as a
	join fa_model.sp5m_result as b
	on a.prim_key = b.gid
	left join fa_model.input_recortes_geo_5570 as c
	on a.ibgecode = c.cd_mun
	group by c.cd_mun, c.nm_mun)
to '/postgresql/passivos_ibge_municipio.csv'
with delimiter ';'
csv header


-- Passivo por imovel
create view fa_model.sp5m_ibge_ruralpr_deficit as
	select
		a.prim_key,
		a.app_deficit,
		a.lr_deficit,
		a.tot_mf,
		b.geom
		from fa_model.sp5m_result_ibge_processed as a
		join fa_model.sp5m_result as b
		on a.prim_key = b.gid
		where a.bool_app = 1 or bool_lr = 1

-- Ativo
drop view if exists fa_model.sp5m_ibge_ruralpr_surplus
create view fa_model.sp5m_ibge_ruralpr_surplus as
	select
		a.prim_key,
		a.not_protected,
		b.geom
		from fa_model.sp5m_result_ibge_processed as a
		join fa_model.sp5m_result as b
		on a.prim_key = b.gid
		where a.not_protected > 0

-- Total por mesoregiao
select
	nm_meso,
	sum(a.lr_deficit),
	sum(a.app_deficit),
	sum(a.not_protected)	
from fa_model.sp5m_result_ibge_processed as a
join fa_model.input_recortes_geo_5570 as b
on a.ibgecode = b.cd_mun
group by b.nm_meso
order by b.nm_meso ASC

