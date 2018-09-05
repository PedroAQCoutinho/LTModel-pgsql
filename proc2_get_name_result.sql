ALTER TABLE lt_model.result
ADD COLUMN IF NOT EXISTS name TEXT;

UPDATE lt_model.result a
SET name = b.:var_column
FROM lt_model.:var_table b
WHERE a.table_source = :'var_table' AND a.original_gid = b.gid;

