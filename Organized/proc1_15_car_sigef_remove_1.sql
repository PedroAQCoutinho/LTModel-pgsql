DROP TABLE IF EXISTS lt_model.proc1_14_car_sigef_cleaned;
CREATE TABLE lt_model.proc1_14_car_sigef_cleaned AS
SELECT *
FROM lt_model.proc1_13_car_sigef WHERE area_loss < (SELECT param_value FROM lt_model.params WHERE param_name = 'car_incra_tolerance');

CREATE TABLE lt_model.lt_model_car_po AS
SELECT * FROM lt_model.proc1_13_car_sigef
WHERE NOT is_premium;

CREATE TABLE lt_model.lt_model_car_pr AS
SELECT * FROM lt_model.proc1_13_car_sigef
WHERE is_premium;