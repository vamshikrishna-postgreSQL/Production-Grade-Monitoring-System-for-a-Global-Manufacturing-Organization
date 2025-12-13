## 1. System Overview and Design Principles
### 1.1 Design Principles
- Data Sovereignty: Regional data isolation with no cross-border transfers
- High Availability: Multi-node clusters with automated failover
- Scalability: Horizontal scaling within regions
- Security-First: Defense in depth with multiple security layers
- Operational Excellence: Automated monitoring and recovery
### 1.2 Archicture Philosophy
- TimescaleDB (PostgreSQL extension) for time-series optimization
- Multi-region deployment with independent regional clusters
- Active-passive DR within each region
- Continuous archival to meet 18-month retention

## 2. Database Cluster Architecture
### 2.1 Regional Cluster Design
#### Per Region Configuration:
- 3-node primary cluster (1 primary + 2 sync replicas)
- 3-node DR cluster (1 standby + 2 async replicas)
- Quorum-based failover using Patroni

<img width="770" height="750" alt="image" src="https://github.com/user-attachments/assets/586a5204-413c-4641-9c65-a2467f1e81ac" />

### 2.2 Node Specifications
#### Database Nodes (Primary Site):
- CPU: 64 cores (AMD EPYC or Intel Xeon)
- RAM: 512GB ECC
- Storage: 
  - OS: 2x 480GB SSD RAID1
  - WAL: 4x 1.92TB NVMe RAID10
  - Data: 24x 7.68TB SSD RAID10
  - Backup staging: 12x 15TB HDD RAID6
- Network: Dual 25Gbps NICs (bonded)
#### DR Nodes:
- Same specs as primary (hot standby capability)
### 2.3 Replication Topology
#### Synchronous Replication:
- Primary → Replica 1 (sync)
- Primary → Replica 2 (sync)
- Quorum: ANY 1 sync replica must acknowledge
#### Asynchronous Replication:
- Primary Site → DR Site (async streaming)
- RPO: <5 minutes via WAL shipping + streaming
#### Replication Slots:
-- Physical replication slots for each replica
   - SELECT * FROM pg_create_physical_replication_slot('replica_1_slot');
   - SELECT * FROM pg_create_physical_replication_slot('replica_2_slot');
   - SELECT * FROM pg_create_physical_replication_slot('dr_primary_slot');

### 2.4 Load Balancing Strategy
#### HAProxy Configuration:
- Write endpoint: Routes to primary only
- Read endpoint: Round-robin across all replicas
- Health checks: Every 2 seconds with pg_isready
- Connection limits: 10,000 max per node
#### Connection Routing:
#### Application Layer:
- Writes → haproxy:5432 (port 5432) → Primary
- Reads → haproxy:5433 (port 5433) → Replicas (RR)
- Admin → Direct node access via VPN

### 2.5 Connection Pooling
#### PgBouncer Configuration (per node):
- Pool mode: Transaction pooling
- Max client connections: 10,000
- Default pool size: 100
- Reserve pool: 10
- Max DB connections: 200
#### Rationale:
- 500K metrics/sec ÷ 50 facilities = 10K metrics/sec per facility
- Batch inserts (1000 rows) = 10 inserts/sec per facility
- Connection reuse for read queries

### 2.6 Network Topology
#### Network Segmentation:
#### DMZ (Public):
- Load balancers
- Application servers
#### Application Tier (10.1.0.0/16):
- Application servers: 10.1.1.0/24
- PgBouncer: 10.1.2.0/24
#### Database Tier (10.2.0.0/16):
- Primary cluster: 10.2.1.0/24
- Replication network: 10.2.2.0/24 (isolated VLAN)
- Backup network: 10.2.3.0/24
#### Management (10.3.0.0/16):
- Monitoring: 10.3.1.0/24
- Bastion hosts: 10.3.2.0/24
#### Firewall Rules:
- App tier → DB tier: Port 5432 (PostgreSQL)
- DB replication: Port 5432 (isolated VLAN)
- Monitoring: Port 9187 (postgres_exporter)
- All traffic encrypted with TLS 1.3

### 3. Storage Architecture
#### 3.1 Storage Tiering Strategy
#### Hot Data (0-30 days):
- Storage: NVMe SSD arrays
- Compression: None (optimized for write throughput)
- Location: Primary tablespace
- Estimated: 40TB per region
#### Warm Data (31-180 days):
- Storage: SATA SSD arrays
- Compression: TimescaleDB native compression (10:1 ratio)
- Location: Warm tablespace
- Estimated: 60TB compressed per region
#### Cold Data (181 days - 18 months):
- Storage: HDD arrays
- Compression: Maximum compression (15:1 ratio)
- Location: Cold tablespace + Object storage (S3/equivalent)
- Estimated: 40TB compressed per region
#### Archive Data (>18 months):
- Storage: Object storage (S3 Glacier/equivalent)
- Compression: Maximum + tar.gz
- Retention: 7 years for compliance
- Estimated: 20TB per region per year

### 3.2 RAID Configurations
#### WAL Files (Write-Ahead Log):
- RAID 10 (4x 1.92TB NVMe)
- Total capacity: 3.84TB usable
- Rationale: High write throughput, low latency
#### Hot Data:
- RAID 10 (24x 7.68TB SSD)
- Total capacity: 92TB usable
- Rationale: Balance between performance and capacity
#### Warm/Cold Data:
- RAID 6 (12x 15TB HDD)
- Total capacity: 150TB usable
- Rationale: Cost-effective with redundancy
  
### 3.3 Filesystem and Mount Options
XFS Filesystem (recommended for PostgreSQL):
bash
 Format
mkfs.xfs -f -L pgdata /dev/mapper/data_vg
 Mount options (/etc/fstab)
/dev/mapper/data_vg /var/lib/postgresql xfs noatime,nodiratime,nobarrier,logbufs=8,logbsize=256k 0 2
/dev/mapper/wal_vg /var/lib/postgresql/wal xfs noatime,nodiratime,nobarrier,logbufs=8,logbsize=256k 0 2
#### Mount Points:
- `/var/lib/postgresql/14/main` - Main data directory
- `/var/lib/postgresql/wal` - WAL files
- `/var/lib/postgresql/tablespaces/warm` - Warm data
- `/var/lib/postgresql/tablespaces/cold` - Cold data
- `/backup/pg` - Backup staging

### 3.4 Tablespace Layout
#### Hot data (default)
CREATE TABLESPACE hot_data 
LOCATION '/var/lib/postgresql/14/main';
#### Warm data
CREATE TABLESPACE warm_data 
LOCATION '/var/lib/postgresql/tablespaces/warm';
#### Cold data
CREATE TABLESPACE cold_data 
LOCATION '/var/lib/postgresql/tablespaces/cold';
#### Indexes
CREATE TABLESPACE index_space 
    LOCATION '/var/lib/postgresql/tablespaces/indexes';

### 3.5 Backup Storage
#### Backup Strategy:
- Daily full backups: To local backup staging (150TB RAID6)
- Continuous WAL archiving: To S3-compatible object storage
- Incremental backups: Every 6 hours using pg_basebackup
- Snapshot backups: Storage-level snapshots (hourly)
#### Retention Policies:
- Full backups: 14 days local, 30 days object storage
- WAL archives: 14 days for PITR
- Snapshots: 7 days

## 4. High Availability and Disaster Recovery
### 4.1 Primary Site Cluster Configuration
#### Patroni + etcd for HA:
yaml
 Patroni configuration
scope: manufacturing_prod
name: pg_node1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 10.2.1.11:8008

etcd3:
  hosts: 10.3.1.10:2379,10.3.1.11:2379,10.3.1.12:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    synchronous_mode: true
    synchronous_mode_strict: false
    postgresql:
      parameters:
        max_connections: 500
        shared_buffers: 128GB
        effective_cache_size: 384GB
        maintenance_work_mem: 2GB
        wal_buffers: 16MB
        synchronous_commit: remote_apply


Automatic Failover:
- Detection time: 30 seconds
- Failover time: <1 minute
- Triggers: Primary unresponsive, replication lag >100MB

### 4.2 DR Site Setup
#### Geographic Distribution:
- Primary site: Same region, different availability zone
- DR site: Same region, >100km from primary
- Network: Dedicated 10Gbps dark fiber
#### DR Replication:
- Async streaming replication
- WAL shipping every 60 seconds
- Replication lag monitoring: Alert if >5 minutes

### 4.3 Failover Procedures
#### Automatic Failover (Primary Site):
1. Patroni detects primary failure (30s)
2. Elects new leader from sync replicas
3. Promotes replica to primary
4. Updates HAProxy backend
5. Applications reconnect automatically
6. Total time: <60 seconds
#### Manual DR Failover:
bash
 1. Verify DR site readiness
        patronictl -c /etc/patroni/patroni.yml list
 2. Promote DR primary
        patronictl -c /etc/patroni/patroni.yml failover --master dr_primary --candidate dr_primary
 3. Update DNS/load balancer
 4. Redirect applications to DR site
 5. Monitor replication from old primary (when recovered)
RTO: <1 hour, RPO: <5 minutes

### 4.4 Recovery Procedures

#### Point-in-Time Recovery (PITR):
bash
 1. Stop PostgreSQL
 - systemctl stop postgresql
 2. Restore base backup
 - pg_basebackup -D /var/lib/postgresql/14/main -Ft -z -P
 3. Create recovery.conf
 - cat > /var/lib/postgresql/14/main/recovery.signal << EOF
 - restore_command = 'aws s3 cp s3://backups/wal/%f %p'
 - recovery_target_time = '2024-01-15 14:30:00'
EOF
 4. Start recovery
systemctl start postgresql


 ## 5. Security Architecture
 ### 5.1 Network Security
- TLS 1.3 for all connections
- Certificate-based authentication for replication
- IPSec for inter-node communication
- Firewall rules (iptables + cloud security groups)
 ### 5.2 Data Security
- Encryption at rest (LUKS/dm-crypt)
- Encryption in transit (TLS)
- Column-level encryption for sensitive data
- Transparent Data Encryption (TDE) for tablespaces
 ### 5.3 Access Control
- LDAP/AD integration for authentication
- Row-level security for facility isolation
- Audit logging (pgaudit)
- Connection logging and analysis

## 6. Capacity Planning
### 6.1 Current Capacity
- 500K metrics/sec = 43.2 billion/day
- Storage: ~2TB/day uncompressed
- With compression: ~200GB/day (10:1)
- 18 months: ~110TB per region
### 6.2 Growth Planning
- Assume 20% annual growth
- Re-evaluate quarterly
- Scale horizontally by adding facilities to new regions
- Scale vertically by upgrading nodes

## 7. Monitoring and Alerting
#### Key Metrics:
- Replication lag (alert if >60s)
- Connection count (alert at 80% capacity)
- Disk I/O utilization (alert at 70%)
- Query performance (alert if p95 >1s)
- Backup success/failure
- Disk space (alert at 75% full)
#### Tools:
- Prometheus + postgres_exporter
- Grafana dashboards
- PagerDuty for alerts
- Custom health check script
