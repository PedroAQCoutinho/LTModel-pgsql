--
-- PostgreSQL database dump
--

-- Dumped from database version 14.4 (Ubuntu 14.4-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.4 (Ubuntu 14.4-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: inputs; Type: TABLE; Schema: lt_model; Owner: postgres
--

CREATE TABLE lt_model.inputs (
    proc_order integer,
    table_name text,
    ownership_class text,
    sub_class text,
    where_clause text,
    fla_proc boolean,
    layer_name text,
    layer_source text,
    year smallint,
    orig_name text,
    id integer NOT NULL,
    column_name text,
    CONSTRAINT inputs_ownership_class_check CHECK ((ownership_class = ANY (ARRAY['PC'::text, 'PL'::text, 'NP'::text, 'ND'::text]))),
    CONSTRAINT inputs_sub_class_check CHECK ((sub_class = ANY (ARRAY['ML'::text, 'TI'::text, 'TI_H'::text, 'TI_N'::text, 'UCPI'::text, 'UCUS'::text, 'APA'::text, 'ARU'::text, 'QL'::text, 'COM'::text, 'CAR'::text, 'CARpo'::text, 'CARpr'::text, 'AG'::text, 'SIGEF'::text, 'ND'::text, 'ND_B'::text, 'ND_I'::text, 'TRANS'::text, 'URB'::text, 'TLPL'::text, 'TLPC'::text])))
);


ALTER TABLE lt_model.inputs OWNER TO postgres;

--
-- Data for Name: inputs; Type: TABLE DATA; Schema: lt_model; Owner: postgres
--

COPY lt_model.inputs (proc_order, table_name, ownership_class, sub_class, where_clause, fla_proc, layer_name, layer_source, year, orig_name, id, column_name) FROM stdin;
1400	input_florestastipob_sfb_2020	PC	ND_B	\N	t	Floresta Nacional tipo B	SFB	2020	input_florestastipob_sfb_2020	24	nome
1305	input_snci_publico_incra_2020	PC	ND_I	\N	t	Gleba pública inserida na base fundiária do SNCI/INCRA	INCRA	2020	input_snci_publico_incra_2020	23	nome_imove
1300	input_sigef_publico_incra_2020	PC	ND_I	\N	t	Gleba pública inserida na base fundiária do SIGEF/INCRA	INCRA	2020	input_sigef_publico_incra_2020	25	nome_area
1200	input_terralegal_glebasfederais_incra_2016	PC	TLPC	\N	t	Terra não titulada do programa Terra Legal	INCRA	2016	input_terralegal_glebasfederais_incra_2016	22	nome_gleba
1105	lt_model_car_po	PL	CARpo	\N	t	CAR Linha	SFB	2019	lt_model_car_po	1	cod_imovel
1100	lt_model_car_pr	PL	CARpr	\N	t	CAR Premium	SFB	2019	lt_model_car_pr	2	cod_imovel
1000	lt_model_incra_pr	PL	SIGEF	\N	t	Imóvel rural privado certificado no sistema do INCRA	INCRA	2019	lt_model_incra_pr	39	cod
990	input_terralegal_particular_incra_2016	PL	TLPL	\N	t	Terra titulada do programa Terra Legal	INCRA	2016	input_terralegal_particular_incra_2016	38	name
705	input_florestastipoa_militar_sfb_2020	PC	ML	\N	t	Área Militar inserida em Floresta Nacional tipo A	SFB	2020	input_florestastipoa_militar_sfb_2020	28	nome
700	input_bi_am_areamilitar_1000_2016_ibge	PC	ML	\N	t	Área Militar	IBGE	2016	input_bi_am_areamilitar_1000_2016_ibge	29	nome
550	input_car_ast_cleaned	PC	CAR	\N	f	Imoveis do CAR do tipo AST	SFB	2020	pa_br_20210412_areaimovel_albers	46	cod_imovel
500	input_assentamentos_incra_2020	PC	ARU	\N	t	Assentamentos Rurais	INCRA	2020	input_assentamentos_incra_2020	4	nome_proje
450	input_florestastipoa_comunitario_sfb_2020	PC	COM	\N	t	Território Comunitário inserido em Floresta Nacional tipo A	SFB	2020	input_florestastipoa_comunitario_sfb_2020	21	nome
440	input_car_pct	PL	CAR	\N	f	Imoveis do CAR do tipo PCT	SFB	2020	pa_br_20210412_areaimovel_albers	45	cod_imovel
300	input_quilombolas_incra_2020	PL	QL	\N	t	Território Quilombola	INCRA	2020	input_quilombolas_incra_2020	19	nm_comunid
150	input_ucs_mma_2019_simex	PC	UCUS	grupo4 LIKE 'US'	t	Unidade de Conservação de Uso Sustentável (exceto APA)	MMA	2019	input_ucs_mma_2019	43	nome_uc1
100	input_ucs_mma_2019_simex	PC	UCPI	grupo4 LIKE 'PI'	t	Unidade de Conservação de Proteção Integral (exceto APA)	MMA	2019	input_ucs_mma_2019	42	nome_uc1
90	input_terrasindigenas_funai_2020	PC	TI_N	fase_ti IN ('Em Estudo', 'Encaminhada RI',  'Delimitada')	t	Terra Indígena	FUNAI	2020	input_terrasindigenas_funai_2020	40	terrai_nom
80	input_terrasindigenas_funai_2020	PC	TI_H	fase_ti IN ('Declarada', 'Regularizada', 'Homologada')	t	Terra Indígena	FUNAI	2020	input_terrasindigenas_2019_funai	41	terrai_nom
56	input_hidrografia_massadagua_250_2017_ibge	NP	AG	\N	f	Massas d´água em escala 1:250.000	IBGE	2017	input_hidrografia_massadagua_250_2017_ibge	9	nome
55	input_hidrografia_bancoareia_250_2015_ibge	NP	AG	\N	f	Bancos de areia em escala 1:250.000	IBGE	2015	input_hidrografia_bancoareia_250_2015_ibge	10	\N
54	input_hidrografia_trecho_massadagua_250_2019_ibge	NP	AG	\N	f	Trechos de massa d'água E de massas d'água em escala 1:250.000	IBGE	2019	input_hidrografia_trecho_massadagua_250_2019_ibge	44	nome
50	input_ferrovia_2015_ibge_30m	NP	TRANS	\N	f	Ferrovia (exceto trechos planejados) – buffer de 30m	IBGE	2015	input_ferrovia_2015_ibge_30m	27	nome
45	input_ferrovia_2018_mi_30m	NP	TRANS	\N	f	Ferrovia (Ministério Infraestrutura) – buffer de 30m	MI	2018	input_ferrovia_2018_mi_30m	26	linha_fe_4
40	input_rod_estaduais_2018_dnit_15m	NP	TRANS	\N	f	Rodovia estadual simples (exceto trechos planejados) – buffer de 15m	DNIT	2018	input_rod_estaduais_2018_dnit_15m	14	rod_codigo
35	input_rod_2019_ibge_15m	NP	TRANS	\N	f	Trecho rodoviário (exceto trechos pavimentados) – buffer de 15m	IBGE	2019	input_rod_2019_ibge_15m	31	codtrechor
30	input_rod_federais_2020_dnit_15m	NP	TRANS	\N	f	Rodovia federal simples (exceto rodovia planejada) – buffer de 15m	DNIT	2020	input_rod_federais_2020_dnit_15m	17	vl_codigo
25	input_rod_2019_ibge_30m	NP	TRANS	\N	f	Trecho rodoviário pavimentado – buffer de 30m	IBGE	2019	input_rod_2019_ibge_30m	30	codtrechor
20	input_rod_federais_2020_dnit_30m	NP	TRANS	\N	f	Rodovia federal simples pavimentada – buffer de 30m	DNIT	2020	input_rod_federais_2020_dnit_30m	18	vl_codigo
15	input_rod_estaduais_2018_dnit_30m	NP	TRANS	\N	f	Rodovia estadudal simples pavimentada – buffer de 30m	DNIT	2018	input_rod_estaduais_2018_dnit_30m	15	rod_codigo
10	input_rod_federais_2020_dnit_60m	NP	TRANS	\N	f	Rodovia federal duplicada – buffer de 60m	DNIT	2020	input_rod_federais_2020_dnit_60m	16	vl_codigo
5	input_rod_estaduais_2018_dnit_60m	NP	TRANS	\N	f	Rodovia estadual duplicada – buffer de 60m	DNIT	2018	input_rod_estaduais_2018_dnit_60m	13	rod_codigo
0	input_urbano_ibge_2019	NP	URB	\N	f	Área urbana em escala 1:250.000	IBGE	2019	input_urbano_ibge_2019	11	nome
\.


--
-- Name: inputs inputs_pkey1; Type: CONSTRAINT; Schema: lt_model; Owner: postgres
--

ALTER TABLE ONLY lt_model.inputs
    ADD CONSTRAINT inputs_pkey1 PRIMARY KEY (id);


--
-- Name: inputs uc_inputs; Type: CONSTRAINT; Schema: lt_model; Owner: postgres
--

ALTER TABLE ONLY lt_model.inputs
    ADD CONSTRAINT uc_inputs UNIQUE (proc_order, fla_proc);


--
-- Name: ix_inputs; Type: INDEX; Schema: lt_model; Owner: postgres
--

CREATE INDEX ix_inputs ON lt_model.inputs USING btree (proc_order DESC);

ALTER TABLE lt_model.inputs CLUSTER ON ix_inputs;


--
-- PostgreSQL database dump complete
--

