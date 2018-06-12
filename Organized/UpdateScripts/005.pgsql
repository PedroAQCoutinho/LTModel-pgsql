INSERT INTO lt_model.params (param_name, param_desc, param_value)
VALUES ('car_premium_tolerance', 'Porcentagem da área do imóvel que precisa permanecer para considerar CAR premium Ex: 0.95 = 95% da área do imóvel precisa permanecer.', 0.95);

--------------------
-- ROLLBACK
--------------------
-- DELETE FROM lt_model.params WHERE param_name = 'car_premium_tolerance';