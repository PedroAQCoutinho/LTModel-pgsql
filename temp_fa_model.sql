(1,AF,FLest,MATA,217.75,65.33,37.39,32.24,37.39,6.16) VN65 >= 20%
(2,AF,FLest,MATA,217.75,37.02,37.39,32.24,37.39,6.16) 10% <= VN65 < 20% AND AREA > 100ha
(3,AF,FLest,MATA,95.00,14.25,16.15,13.30,16.15,2.85) 10% <= VN65 < 20% AND AREA < 100ha
(4,AF,FLest,MATA,217.75,15.24,37.39,32.24,37.39,6.16) VN65 < 10% AND AREA > 100ha
(5,AF,FLest,MATA,95.00,6.65,16.15,13.30,16.15,2.85) VN65 <10% AND AREA < 100ha
(6,CE,Svsv,CERRADO,217.75,65.33,65.33,0.00,26.13,17.42) VN89 >= 20%
(7,CE,Svsv,CERRADO,217.75,65.33,28.31,0.00,10.00,33.55) VN89 < 20%
(8,CE,Svsv,CERRADO,217.75,65.33,28.31,0.00,40.00,3.55) VN89 < 20%

create table fa_model.art68_temp_imoveisteste as 
select * from fa_model.art68_imoveis_proc11
limit 0

insert into fa_model.art68_temp_imoveisteste (prim_key, bioma, fito, carta_ibge, area_imovel, vn65, vn89r, vn89d, vn08, def08)
values (1,'AF','FLest','MATA',217.75,65.33,37.39,32.24,37.39,6.16),
(2,'AF','FLest','MATA',217.75,37.02,37.39,32.24,37.39,6.16),
(3,'AF','FLest','MATA',95.00,14.25,16.15,13.30,16.15,2.85),
(4,'AF','FLest','MATA',217.75,15.24,37.39,32.24,37.39,6.16),
(5,'AF','FLest','MATA',95.00,6.65,16.15,13.30,16.15,2.85),
(6,'CE','Svsv','CERRADO',217.75,65.33,65.33,0.00,26.13,17.42),
(7,'CE','Svsv','CERRADO',217.75,65.33,28.31,0.00,10.00,33.55)


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