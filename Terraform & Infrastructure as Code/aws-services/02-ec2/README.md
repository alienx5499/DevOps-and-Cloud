# AWS Service Deep-Dive: Elastic Compute Cloud (EC2)

Comprehensive engineering guide covering resizable cloud compute instances, virtualization mechanisms, storage attachments, networking boundaries, and state lifecycle management on Amazon Web Services.

---

## 1. EC2 Architecture & Component Hierarchy

<img width="5717" height="3565" alt="EC2 Architecture and Component Hierarchy" src="https://github.com/user-attachments/assets/71fb338b-b789-40c4-95e7-5f110a5f93d5" />

---

## 2. Core Concepts & Building Blocks

### 2.1 Amazon Machine Images (AMI)
A pre-configured template containing the operating system (Ubuntu, Amazon Linux 2023, RHEL, Windows), application server, and default packages. AMIs can be AWS-managed, Marketplace images, or custom-baked via HashiCorp Packer.

### 2.2 Instance Types & Families
Categorized by hardware resource ratios:
- **General Purpose (`t4g`, `m6i`, `m7g`):** Balanced compute, memory, and networking for microservices, web servers, and development sandboxes.
- **Compute Optimized (`c6i`, `c7g`):** High ratio of compute power for batch processing, machine learning inference, and media transcoding.
- **Memory Optimized (`r6i`, `r7g`):** Large memory footprints for in-memory caches (Redis) and high-throughput transactional databases.
- **Storage Optimized (`i3en`, `d3`):** High sequential disk read/write throughput and direct NVMe local storage.

### 2.3 SSH Key Pairs
Asymmetric cryptographic keys used to authenticate SSH or RDP sessions. AWS injects the public key into `~/.ssh/authorized_keys` at launch via cloud-init. The private key (`.pem`) remains exclusively with the client.

### 2.4 Security Groups vs Network ACLs
A **Security Group** acts as a virtual stateful firewall at the individual instance/ENI level:
- Stateful: If inbound traffic is allowed, outbound response traffic is automatically permitted regardless of outbound rules.
- Whitelist-only: Evaluates allow rules exclusively (no explicit deny rules).

### 2.5 Elastic Block Store (EBS)
Network-attached block storage volumes providing persistent data independent of the instance lifecycle:
- **gp3 (General Purpose SSD):** Baseline 3,000 IOPS and 125 MB/s throughput with independent scaling.
- **io2 Block Express (Provisioned IOPS):** Up to 256,000 IOPS for mission-critical relational databases.
- **Snapshots:** Point-in-time incremental backups stored durably in Amazon S3.

### 2.6 Public vs Private IPv4 Addresses
- **Private IP:** Assigned automatically from the VPC subnet CIDR; retained across instance stop and start cycles; used for internal VPC communication.
- **Public IP:** Ephemeral address allocated from AWS pool; released upon instance stop.
- **Elastic IP (EIP):** Static public IPv4 address attached to an instance or NAT Gateway, retained until explicitly deleted.

---

## 3. EC2 Instance Lifecycle Flow

<img width="8040" height="4225" alt="EC2 Instance Lifecycle Flow" src="https://github.com/user-attachments/assets/2285f322-bc63-4b70-af07-427023ce9ad6" />

---

## 4. Common Use Cases

1. **Web and Application Hosting:** Running NGINX, Node.js, Python Flask/FastAPI, or Java Spring microservices inside Auto Scaling Groups behind an Application Load Balancer.
2. **Self-Managed Databases:** Deploying PostgreSQL, MySQL, MongoDB, or Cassandra requiring custom OS tuning or kernel extensions.
3. **CI/CD Self-Hosted Runners:** Running GitHub Actions runners or Jenkins agents on spot instances to reduce build costs.
