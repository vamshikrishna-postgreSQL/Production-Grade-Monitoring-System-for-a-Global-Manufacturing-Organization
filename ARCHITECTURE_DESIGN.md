# 1. System Overview
This system ingests, stores, and analyzes 500,000 metrics/sec from 10,000+ machines across 50 global manufacturing facilities, with:
- 18-month retention
- Regional data sovereignty
- 99.99% uptime
- 14-day PITR
- <1-hour RTO, <5-minute RPO
- Real-time + batch analytics
- The design uses TimescaleDB on PostgreSQL, deployed in regionally isolated clusters with cross-region DR replication where allowed by policy.
 
# 2. Hardware & Infrastructure Specification
## Database Nodes (per region)

|      Role                          |      Count               |      Specification                                   |
|------------------------------------|--------------------------|------------------------------------------------------|
|     Primary                        |     3-node HA cluster    |     32 cores, 256GB RAM, NVMe SSD   RAID10           |
|     Standby                        |     2                    |     Same as primary                                  |
|     Analytics replica              |     1–2                  |     24 cores, 128GB RAM, larger   storage, RAID10    |
|     Backup / WAL archive server    |     1                    |     High-capacity (HDD), RAID6                       |

# 3. Database Cluster Architecture
## Node Roles
- Node 1: Primary writer
- Node 2 & 3: Synchronous standby pair
- Node 4 & 5: Asynchronous DR-feasible standbys
- Node 6+: Read-only analytics replicas
## Replication Topology
- Primary
  - Sync Standby A (quorum)
  - Sync Standby B (quorum)
  - Async Standby C (local region)
  - Async DR Standby D (remote region)
- Synchronous quorum: ANY 1 among two sync standbys
- WAL replication mode: streaming + WAL-G archiving
- PITR: WAL-G + object storage retention (14 days)
## Connection Pooling
- PgBouncer in transaction pooling mode
- 3-node highly available pooler cluster per region

# 4. Network Design
- Segmented VLANs:
  - INGEST VLAN
  - DB INTERNAL VLAN
  - REPLICATION VLAN
  - BACKUP VLAN
-   MGMT VLAN
- TLS enforced end-to-end
- mTLS for machine-to-gateway ingestion

# 5. Storage Architecture
## Hot/Warm/Cold Tiering
|      Tier     |      Retention     |      Storage          |      Use                    |
|---------------|--------------------|-----------------------|-----------------------------|
|     Hot       |     30–60 days     |     NVMe RAID10       |     Real-time dashboards    |
|     Warm      |     6 months       |     SSD RAID10        |     Analytics               |
|     Cold      |     18 months      |     HDD RAID6 / S3    |     Compliance              |

TimescaleDB compression enabled at 60 days.

## RAID
- Critical sensor data: RAID10 NVMe
- Historical/compressed chunks: RAID6 SSD/HDD
## Tablespace Layout
- ts_hot      → NVMe
- ts_warm     → SSD
- ts_archive  → HDD/OBJECT STORAGE
- ts_indexes  → NVMe
- ts_audit    → SSD
Backup storage: object storage + Glacier archive.

# 6.High Availability & Disaster Recovery
## HA Strategy
- Patroni-managed PostgreSQL cluster
- Etcd or Consul for consensus
- Synchronous quorum replication
- 99.99% uptime achieved via:
  - Rolling upgrades without downtime
  - Connection pooler failover
  - Multi-node redundancy
## DR Site
- Async replica with:
  - WAL-G continuous archiving
  - Cross-region bandwidth shaping
- DR RPO: ≤5 min
- DR RTO: ≤1 hour with automated promote scripts
## Failover Procedure
- Loss of primary detected by Patroni
- Quorum standbys elect new primary
- PgBouncer routes traffic to new primary
- Old primary fenced and rejoined after validation
## Switchover Procedure
- Triggered manually during maintenance
- Uses Patroni switchover command
- SLA: <30 seconds
