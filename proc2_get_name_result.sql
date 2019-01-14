ALTER TABLE lt_model.result_:var_priority
ADD COLUMN IF NOT EXISTS name TEXT;

UPDATE lt_model.result_:var_priority a
SET name = b.:var_column
FROM lt_model.:var_table b
WHERE a.table_source = lt_model.simplify_multipolygon_name(LEFT(:'var_table', 63)) AND a.original_gid = b.gid;

