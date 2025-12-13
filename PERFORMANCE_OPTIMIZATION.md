# Index Strategy
### Pattern 1 (real-time)

CREATE INDEX ON sensor_data
  (facility_id, machine_id, timestamp DESC)
WHERE timestamp > now() - interval '1 hour';

### Pattern 2 (5-min buckets)

CREATE INDEX ON sensor_data (facility_id, timestamp, metric_name);

### Pattern 3 (daily summaries)

CREATE INDEX ON daily_summaries (report_date, facility_id, machine_type);

### Pattern 4 (anomaly detection)

CREATE INDEX ON sensor_data
  (timestamp)
  WHERE value > threshold_high OR value < threshold_low;
