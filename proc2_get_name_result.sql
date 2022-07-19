ALTER TABLE recorte.result
ADD COLUMN IF NOT EXISTS name TEXT;

UPDATE recorte.result a
SET name = b.:var_column
FROM recorte.:var_table b
WHERE a.table_source = recorte.simplify_multipolygon_name(LEFT(:'var_table', 63)) AND a.original_gid = b.gid;

