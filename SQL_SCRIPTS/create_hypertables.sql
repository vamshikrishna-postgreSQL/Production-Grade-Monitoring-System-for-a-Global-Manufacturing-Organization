-- Creates hypertables for all time-series datasets
SELECT create_hypertable(
  'sensor_data',
  'timestamp',
  chunk_time_interval => INTERVAL '1 day',
  partitioning_column => 'facility_id',
  number_partitions => 50
);
