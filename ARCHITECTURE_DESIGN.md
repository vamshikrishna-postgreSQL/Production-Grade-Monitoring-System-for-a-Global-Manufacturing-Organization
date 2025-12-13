1. System Overview
  This system ingests, stores, and analyzes 500,000 metrics/sec from 10,000+ machines across 50 global manufacturing facilities, with:
  •	18-month retention
  •	Regional data sovereignty
  •	99.99% uptime
  •	14-day PITR
  •	<1-hour RTO, <5-minute RPO
  •	Real-time + batch analytics
  The design uses TimescaleDB on PostgreSQL, deployed in regionally isolated clusters with cross-region DR replication where allowed by policy.
 
2. Hardware & Infrastructure Specification
Database Nodes (per region)
Role	Count	Specification
Primary	3-node HA cluster	32 cores, 256GB RAM, NVMe SSD RAID10
Standby	2	Same as primary
Analytics replica	1–2	24 cores, 128GB RAM, larger storage, RAID10
Backup / WAL archive server	1	High-capacity (HDD), RAID6
Networking: 25–40 GbE, redundant paths, isolated VLANs per tier.
