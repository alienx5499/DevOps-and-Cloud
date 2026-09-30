# AWS Service Deep-Dive: Managed Databases (DynamoDB & RDS)

Comprehensive comparison and architecture guide covering managed NoSQL key-value/document stores versus managed relational transactional database engines on Amazon Web Services.

---

## 1. Managed Database Paradigms Overview

<img width="5649" height="3305" alt="DynamoDB vs RDS Managed Cloud Database Architecture" src="https://github.com/user-attachments/assets/d14bdd4a-3168-42e0-b714-98b59b119795" />

---

## 2. Amazon DynamoDB (Serverless NoSQL)

### 2.1 Core Concepts
- **Tables:** Collections of data items. DynamoDB requires no instance provisioning, disk sizing, or server patching.
- **Items:** A collection of attributes, analogous to a row in a relational database. Maximum item size is 400 KB.
- **Attributes:** Fundamental data element (string, number, binary, boolean, null, list, map). Schemaless: each item can have different attributes except for the primary key.

### 2.2 Primary Key Architectures
1. **Simple Primary Key (Partition Key only):** A single attribute used by an internal hash function to distribute items evenly across physical storage partitions. Example: `UserID`.
2. **Composite Primary Key (Partition Key + Sort Key):** The partition key determines node placement; items sharing the same partition key are stored together in sorted order by the sort key. Example: `TenantID` (Partition Key) + `Timestamp` (Sort Key).

### 2.3 Performance & Scaling Modes
- **On-Demand Capacity:** Automatically accommodates shifting workloads with pay-per-request pricing.
- **Provisioned Capacity:** Set explicit Read Capacity Units (RCUs) and Write Capacity Units (WCUs) with target-tracking auto-scaling.
- **DynamoDB Accelerator (DAX):** In-memory cache providing microsecond response times for read-heavy workloads.

### 2.4 DynamoDB Common Use Cases
1. **User Session Stores & Profiles:** Ultra-fast key-value lookups with TTL (Time to Live) automatic session expiration.
2. **Shopping Carts & Order Tracking:** High-concurrency e-commerce operations during flash sales.
3. **Gaming Leaderboards:** Fast item reads and atomic counter increments.

---

## 3. Amazon Relational Database Service (RDS)

### 3.1 Supported Database Engines
- Amazon Aurora (MySQL & PostgreSQL compatible, cloud-native storage engine)
- PostgreSQL
- MySQL
- MariaDB
- Oracle Database
- Microsoft SQL Server

### 3.2 High Availability: Multi-AZ Deployments
Provisions a synchronous standby replica in a different Availability Zone within the same region:
- **Synchronous Replication:** Transactions commit to both primary and standby disks before acknowledging completion.
- **Automated Failover:** If the primary instance experiences hardware degradation, network failure, or OS patching, the DNS endpoint automatically fails over to the standby instance within 60 to 120 seconds with zero manual intervention.

### 3.3 Scalability: Read Replicas
Asynchronously replicates data from the primary instance to up to 15 read replicas within the same or different AWS regions:
- Offloads heavy read queries, reporting pipelines, and BI dashboards.
- Can be promoted to a standalone primary database in disaster recovery scenarios.

### 3.4 Automated Backups & Point-in-Time Recovery (PITR)
RDS creates daily storage volume snapshots and continuously captures transaction logs to S3. Enables restoring the database to any specific second within a retention window of up to 35 days.

---

## 4. Architectural Comparison: DynamoDB vs RDS

| Architectural Criteria | Amazon DynamoDB | Amazon RDS |
| :--- | :--- | :--- |
| **Data Model** | Key-Value / Document (JSON) | Relational (Tables, Rows, Foreign Keys) |
| **Schema** | Schemaless (dynamic attributes) | Rigid schema with declarative DDL |
| **Query Flexibility** | Lookup by primary key or secondary indexes | Complex SQL queries, subqueries, and multi-table JOINs |
| **Latency Profile** | Predictable single-digit millisecond latency | Varies based on query complexity and indexing |
| **Scaling Model** | Automatic horizontal partitioning | Vertical instance sizing + Read Replicas (Aurora scales storage auto) |
| **Maintenance & Patching** | 100% Serverless (Zero host management) | Automated OS patching during configurable maintenance windows |
| **ACID Guarantees** | Strong consistency & 25-item ACID transactions | Full multi-table ACID transactions out of the box |
