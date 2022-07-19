INSERT INTO recorte.params (param_name, param_desc, param_value)
VALUES ('incra_pr_exclusion_tolerance', 'Porcentagem para considerar o imóvel do SIGEF como descaracterizado multiplicado por 100. Ex: 50%, param_value = 50', 50);

UPDATE recorte.log_operation
SET nom_operation = 'incra_pr_mischaracterized'
WHERE nom_operation = 'sigef_clean_lost_95area';
--------------------
-- ROLLBACK
--------------------
-- DELETE FROM recorte.params WHERE param_name = 'incra_pr_exclusion_tolerance';

-- UPDATE recorte.log_operation
-- SET nom_operation = 'sigef_clean_lost_95area'
-- WHERE nom_operation = 'incra_pr_mischaracterized';