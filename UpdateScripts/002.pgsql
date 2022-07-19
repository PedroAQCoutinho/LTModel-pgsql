CREATE TABLE recorte.params (
    id SERIAL PRIMARY KEY,
    param_name TEXT UNIQUE,
    param_desc TEXT,
    param_value DECIMAL
);

--------------------
-- ROLLBACK
--------------------
-- DROP TABLE recorte.params;