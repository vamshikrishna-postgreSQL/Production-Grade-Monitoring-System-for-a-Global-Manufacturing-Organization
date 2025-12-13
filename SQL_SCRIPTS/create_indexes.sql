-- Pattern 1
CREATE INDEX idx_rt_monitoring
ON sensor_data (facility_id, machine_id, timestamp DESC)
WHERE timestamp > now() - interval '1 hour';

-- Pattern 2
CREATE INDEX idx_facility_analytics
ON sensor_data (facility_id, timestamp, metric_name);

-- Pattern 3
CREATE INDEX idx_daily_summaries
ON daily_summaries (report_date, facility_id, machine_type);

-- Pattern 4
CREATE INDEX idx_threshold_anomalies
ON sensor_data (timestamp)
WHERE value > threshold_high OR value < threshold_low;
