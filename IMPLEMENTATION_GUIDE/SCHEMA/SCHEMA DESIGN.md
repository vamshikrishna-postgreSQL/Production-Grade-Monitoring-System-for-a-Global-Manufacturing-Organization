# REFERENCE TABLE
CREATE TABLE facilities (
  facility_id UUID PRIMARY KEY,
  region TEXT,
  name TEXT
);

CREATE TABLE machines (
  machine_id UUID PRIMARY KEY,
  facility_id UUID REFERENCES facilities,
  machine_type TEXT
);


Hypertable
CREATE TABLE sensor_data (
  timestamp TIMESTAMPTZ NOT NULL,
  facility_id UUID NOT NULL,
  machine_id UUID NOT NULL,
  metric_name TEXT NOT NULL,
  value DOUBLE PRECISION,
  threshold_high DOUBLE PRECISION,
  threshold_low DOUBLE PRECISION
);

SELECT create_hypertable(
  'sensor_data',
  'timestamp',
  partitioning_column => 'facility_id',
  number_partitions => 32,
  chunk_time_interval => INTERVAL '1 day'
);


Compression & Retention

ALTER TABLE sensor_data SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'facility_id, machine_id, metric_name'
);

SELECT add_compression_policy('sensor_data', INTERVAL '30 days');
SELECT add_retention_policy('sensor_data', INTERVAL '18 months');

