UPDATE recorte.inputs 
SET table_name = 'lt_model_incra_pr'
WHERE id = 39;

--------------------
-- ROLLBACK
--------------------
-- UPDATE recorte.inputs 
-- SET table_name = 'lt_model_sigef'
-- WHERE id = 39;