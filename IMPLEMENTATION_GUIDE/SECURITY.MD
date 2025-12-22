### Role Hirerchy

| Role     | Permissions    |
| -------- | -------------- |
| readonly | SELECT         |
| engineer | SELECT, INSERT |
| admin    | ALL            |
| auditor  | SELECT + audit |

### Row-Level Security

ALTER TABLE sensor_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY facility_isolation
ON sensor_data
USING (facility_id = current_setting('app.facility_id')::uuid);

### LDAP Integration
- PostgreSQL LDAP auth in pg_hba.conf
- Facility attribute mapped to session variable


