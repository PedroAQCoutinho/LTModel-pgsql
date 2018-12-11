proc_order;table_name;ownership_class;sub_class;where_clause;fla_proc;layer_name;layer_source;year;orig_name;id;column_name
59;input_hidrografia_massadagua_1000_2014_ibge;NP;AG;;f;Massas d´água em escala 1:1.000.000;IBGE;2015;pa_br_hidrografia_massadagua_1000_2014_ibge;7;nome
58;input_hidrografia_bancoareia_1000_2014_ibge;NP;AG;;f;Bancos de areia em escala 1:1.000.000;IBGE;2015;pa_br_hidrografia_bancoareia_1000_2014_ibge;8;
57;input_hidrografia_trechomassadagua_1000_2014;NP;AG;;f;Trechos de massa d'água 1:1.000.000;IBGE;2015;pa_br_hidrografia_trechomassadagua_1000_2014;45;nome
56;input_hidrografia_massadagua_250_2017_ibge;NP;AG;;t;Massas d´água em escala 1:250.000;IBGE;2017;pa_br_hidrografia_massadagua_250_2015_ibge;9;nome
55;input_hidrografia_bancoareia_250_2017_ibge;NP;AG;;t;Bancos de areia em escala 1:250.000;IBGE;2017;pa_br_hidrografia_bancoareia_250_2015_ibge;10;
54;input_hidrografia_trechomassadagua_250_2017;NP;AG;;t;Trechos de massa d'água 1:250.000;IBGE;2017;pa_br_hidrografia_trechomassadagua_250_2015;44;nome
50;input_ferrovia_2015_ibge_30m;NP;TRANS;;t;Ferrovia (exceto trechos planejados) – buffer de 30m;IBGE;2015;pa_br_ferrovia_2015_ibge_complementodnit_30m;27;nome
45;input_ferrovia_pnv_dnit_2016_30m;NP;TRANS;;t;Ferrovia (complementação à base do DNIT) – buffer de 30m;DNIT;2016;pa_br_ferrovia_pnv_2016_dnit_menosplanejadas_30m;26;ferrovia
40;input_rod_estaduais_2016_dnit_15m;NP;TRANS;;t;Rodovia estadual simples (exceto trechos planejados) – buffer de 15m;DNIT;2016;pa_br_rodovias_estaduais_2016_dnit_menosplanejadas;14;rod_codigo
35;input_rod_2015_ibge_15m;NP;TRANS;;t;Trecho rodoviário (exceto trechos pavimentados) – buffer de 15m;IBGE;2015;pa_br_trechorodoviario_2015_ibge_menospavimentadas_15m;31;codtrechor
30;input_rod_federais_2016_dnit_15m;NP;TRANS;;t;Rodovia federal simples (exceto rodovia planejada) – buffer de 15m;DNIT;2016;pa_br_rodovias_federais_2016_dnit_menosplanejadas_15m;17;ds_coinc
25;input_rod_2015_ibge_pavimentadas_30m;NP;TRANS;;t;Trecho rodoviário pavimentado – buffer de 30m;IBGE;2015;pa_br_trechorodoviario_2015_ibge_pavimentadas_30m;30;codtrechor
20;input_rod_federais_2016_dnit_pavimentadas_30m;NP;TRANS;;t;Rodovia federal simples pavimentada – buffer de 30m;DNIT;2016;pa_br_rodovias_federais_2016_dnit_pavimentadas_30m;18;vl_codigo
15;input_rod_estaduais_2016_dnit_pavimentadas_30m;NP;TRANS;;t;Rodovia estadudal simples pavimentada – buffer de 30m;DNIT;2016;pa_br_rodovias_estaduais_2016_dnit_pavimentadas_30m;15;rod_codigo
10;input_rod_federais_2016_dnit_60m;NP;TRANS;;t;Rodovia federal duplicada – buffer de 60m;DNIT;2016;pa_br_rodovias_federais_2016_dnit_duplicadas_60m;16;ds_coinc
5;input_rod_estaduais_2016_dnit_60m;NP;TRANS;;t;Rodovia estadual duplicada – buffer de 60m;DNIT;2016;pa_br_rodovias_estaduais_2016_dnit_duplicadas_60m;13;rod_codigo
0;input_urbano_250_2015_ibge;NP;URB;;t;Área urbana  em escala 1:1.000.000;IBGE;2015;pa_br_localidade_areaedificada_bc250_2015_ibge;11;nome
100;lt_model_incra_pr;PL;SIGEF;;t;Imóvel rural privado certificado no sistema do INCRA;INCRA;2016;lt_model_incra_pr;39;cod
200;input_bi_am_terralegal_particulares;PL;TLPL;;t;Terra titulada do programa Terra Legal;INCRA;2015;bi_am_terralegal_particulares;38;nome
700;input_bi_am_areamilitar_1000_2014_ibge;PC;ML;;t;Área Militar;IBGE;2014;bi_am_areamilitar_1000_2014_ibge;29;nome
900;input_florestastipoa_comunitario_2017_sfb;PC;COM;;t;Território Comunitário inserido em Floresta Nacional tipo A;SFB;2015;pa_br_florestastipoa_comunitario_2015_sfb;21;nome
705;input_florestastipoa_ml_2017_sfb;PC;ML;;t;Área Militar inserida em Floresta Nacional tipo A;SFB;2015;pa_br_florestastipoa_ml_2015_sfb;28;nome2
600;input_ucs_2017_mma;PC;UCUS;grupo4 LIKE 'US';t;Unidade de Conservação de Uso Sustentável (exceto APA);MMA;2017;pa_br_ucs_todasmenosapas_2017_mma;43;nome_uc1
500;input_ucs_2017_mma;PC;UCPI;grupo4 LIKE 'PI';t;Unidade de Conservação de Proteção Integral (exceto APA);MMA;2017;pa_br_ucs_todasmenosapas_2017_mma;42;nome_uc1
800;input_acervofundiario_assentamentos_2018_incra;PC;ARU;;t;Assentamentos;INCRA;2018;pa_br_assentamentos_incra_2018;4;nome_proje
1105;lt_model_car_po;PL;CARpo;;t;CAR Linha;SFB;2017;lt_model_car_po;1;cod_imovel
1000;input_terrasindigenas_2017_funai;PC;TI_N;fase_ti IN ('Em Estudo', 'Encaminhada RI',  'Delimitada');t;Terra Indígena;FUNAI;2017;pa_br_terrasindigenas_2017_funai;40;terrai_nom
1100;lt_model_car_pr;PL;CARpr;;t;CAR Premium;SFB;2017;lt_model_car_pr;2;cod_imovel
1305;input_acervofundiario_snci_publico_2018_incra;PC;ND_I;;t;Gleba pública inserida na base fundiária do SNCI/INCRA;INCRA;2018;pa_br_acervoFundiario_snci_publico2018_incra;23;nome_imove
1200;input_bi_am_glebasfederais_terralegal_2015_incra;PC;TLPC;;t;Terra não titulada do programa Terra Legal;INCRA;2015;bi_am_acervofundiario_glebasfederais_terralegal_2015_incra;22;nm_gleba2
1300;input_acervofundiario_sigef_publico_2018_incra;PC;ND_I;;t;Gleba pública inserida na base fundiária do SIGEF/INCRA;INCRA;2018;pa_br_acervoFundiario_sigef_publico_2018_incra;25;nome_area
1400;input_florestatipob_2017_sfb;PC;ND_B;;t;Floresta Nacional tipo B;SFB;2015;pa_br_florestatipob_2015_sfb;24;nome
300;input_acervofundiario_quilombolas_2017_incra;PL;QL;;t;Território Quilombola;INCRA;2017;pa_br_acervofundiario_quilombolas_2015_incra;19;nm_comun3
400;input_terrasindigenas_2017_funai;PC;TI_H;fase_ti IN ('Declarada', 'Regularizada', 'Homologada');t;Terra Indígena;FUNAI;2017;pa_br_terrasindigenas_2017_funai;41;terrai_nom
