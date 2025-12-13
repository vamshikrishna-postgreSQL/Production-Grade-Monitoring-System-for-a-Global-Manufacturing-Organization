## Daily Checklist
- Check replication lag (<5s)
- Verify WAL-G archiving runs
- Monitor chunk creation/compression
- Validate free disk space (≥20%)
## Maintenance
- VACUUM (ANALYZE) on reference tables weekly
- Reindex monthly or after bloat >20%

## Backup & Recovery
### Full + Incremental Strategy
- Full backup: weekly (WAL-G)
- Incremental: continuous WAL archiving
- PITR window: 14 days
### Recovery Test Procedure
- Provision a test instance
- Restore last full backup
- Replay WAL to PITR target
- Validate checksum, queries, and row counts
