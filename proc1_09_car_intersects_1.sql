SET search_path TO lt_model, public;

DROP TABLE IF EXISTS proc1_03_z1_car_intersects;
CREATE TABLE proc1_03_z1_car_intersects
(
  gid BIGINT,
  gid2 BIGINT,
  fla_car_premium boolean,
  fla_car_premium2 boolean,
  new_area double precision
);

CREATE INDEX IF NOT EXISTS  ix_car_intersects ON lt_model.proc1_03_z1_car_intersects USING BTREE (gid, gid2);