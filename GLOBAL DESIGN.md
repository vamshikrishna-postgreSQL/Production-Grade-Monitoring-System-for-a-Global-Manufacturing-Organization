## Global Design – Managing 50 isolated Facilities with Data Sovereignty
- To oversee data management across 50 international facilities while upholding stringent data sovereignty, I would implement a region-centric architecture.
- Facilities are categorized into geographic regions (for instance, EU, North America, APAC), with each region maintaining its own fully autonomous TimescaleDB cluster. All processes related to sensor ingestion, storage, querying, and backups for a facility are confined to its designated region. There is no transfer of raw data across regions, thereby ensuring that EU data remains within Europe and similar sovereignty regulations are upheld in other areas.
- Global visibility is accomplished through the aggregation of metadata only (including counts, health signals, and compliance summaries), which is transmitted to a streamlined global control plane. This facilitates corporate reporting without compromising isolation or sovereignty. Identity and access management is centralized through LDAP/AD, while authorization is enforced locally via row-level security, guaranteeing that users can only access the facilities to which they have rightful access.

              ┌──────────────┐
              │ Global Portal │
              │ (Metadata)   │
              └──────┬───────┘
                     │
     ┌───────────────┼────────────────┐
     │               │                │
┌──────────┐   ┌──────────┐    ┌──────────┐
│ EU Region│   │ US Region│    │ APAC Reg.│
│ DB Clust.│   │ DB Clust.│    │ DB Clust.│
└────┬─────┘   └────┬─────┘    └────┬─────┘
     │              │               │
 [EU Facilities] [US Facilities] [APAC Facilities]

  
              ┌──────────────┐
              │ Global Portal │
              │ (Metadata)   │
              └──────┬───────┘
                     │
     ┌───────────────┼────────────────┐
     │               │                │
┌──────────┐   ┌──────────┐    ┌──────────┐
│ EU Region│   │ US Region│    │ APAC Reg.│
│ DB Clust.│   │ DB Clust.│    │ DB Clust.│
└────┬─────┘   └────┬─────┘    └────┬─────┘
     │              │               │
 [EU Facilities] [US Facilities] [APAC Facilities]

