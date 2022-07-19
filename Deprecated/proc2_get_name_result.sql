ALTER TABLE recorte.result_:var_priority
ADD COLUMN IF NOT EXISTS name TEXT;

UPDATE recorte.result_:var_priority a
SET name = b.:var_column
FROM recorte.:var_table b
WHERE a.table_source = recorte.simplify_multipolygon_name(LEFT(:'var_table', 63)) AND a.original_gid = b.gid;

