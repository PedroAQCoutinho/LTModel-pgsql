INSERT INTO lt_model.params (param_name, param_desc, param_text)
VALUES ('car_table_schema', 'Nome do esquema em que reside a tabela do car', 'car');

INSERT INTO lt_model.params (param_name, param_desc, param_text)
VALUES ('car_table_name', 'Nome da tabela do car', 'pa_br_20180221_areaimovel');

INSERT INTO lt_model.params (param_name, param_desc, param_value)
VALUES ('car_premium_tolerance', 'Porcentagem da área do imóvel que precisa permanecer para considerar CAR premium Ex: 0.95 = 95% da área do imóvel precisa permanecer.', 0.95);

INSERT INTO lt_model.params (param_name, param_desc, param_text)
VALUES ('priority_autointersection', 'Prioridade de autointersecção, S=smaller, L=larger, R=random, obrigatoriamente maiúsculo', 'R');

INSERT INTO lt_model.params (param_name, param_desc, param_value)
VALUES ('car_area_loss_tolerance', 'Perda de área máxima aceitável. Ex: 0.5, todos os CAR que perderam mais de 50% de sua área serão apagados ou mesclados', 0.5);

INSERT INTO lt_model.params (param_name, param_desc, param_value)
VALUES ('car_ci_minimum', 'Mínimo circularity index (CI) aceitável. Ex: 0.12, valores de CI < 0.12 serão removidos', 0.12);

--------------------
-- ROLLBACK
--------------------
-- DELETE FROM lt_model.params WHERE param_name = 'car_premium_tolerance';
-- DELETE FROM lt_model.params WHERE param_name = 'car_table_name';
-- DELETE FROM lt_model.params WHERE param_name = 'car_table_schema';
-- DELETE FROM lt_model.params WHERE param_name = 'priority_autointersection';
-- DELETE FROM lt_model.params WHERE param_name = 'car_area_loss_tolerance';
-- DELETE FROM lt_model.params WHERE param_name = 'car_ci_minimum';