CREATE TABLE facility (
  facility_id int PRIMARY KEY,
  region text NOT NULL,
  name text NOT NULL
);

CREATE TABLE machine (
  machine_id bigint PRIMARY KEY,
  facility_id int REFERENCES facility(facility_id),
  machine_type text NOT NULL,
  name text NOT NULL
);

CREATE TABLE sensor_data (
  facility_id int NOT NULL,
  machine_id bigint NOT NULL,
  metric_name text NOT NULL,
  timestamp timestamptz NOT NULL,
  value double precision NOT NULL,
  threshold_high double precision,
  threshold_low double precision,
  PRIMARY KEY (facility_id, machine_id, timestamp, metric_name)
);

SELECT create_hypertable(
  'sensor_data',
  'timestamp',
  chunk_time_interval => INTERVAL '1 day',
  partitioning_column => 'facility_id',
  number_partitions => 50
);

ALTER TABLE sensor_data SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'machine_id,metric_name'
);

SELECT add_compression_policy('sensor_data', INTERVAL '60 days');
