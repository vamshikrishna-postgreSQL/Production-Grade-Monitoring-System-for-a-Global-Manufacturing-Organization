ALTER TABLE sensor_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY facility_isolation ON sensor_data
  USING (facility_id = current_setting('app.current_facility')::int);
