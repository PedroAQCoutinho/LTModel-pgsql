INSERT INTO recorte.params (param_name, param_desc, param_value)
VALUES ('car_incra_tolerance', 'Máxima sobreposição de CAR com INCRA para remover o CAR da análise. Ex: 0.5, CAR que perder mais de 50% de sua área para propriedades privadas declaradas pelo INCRA serão removidos da análise.', 0.5);

--------------------
-- ROLLBACK
--------------------
-- DELETE FROM recorte.params WHERE param_name = 'car_incra_tolerance';