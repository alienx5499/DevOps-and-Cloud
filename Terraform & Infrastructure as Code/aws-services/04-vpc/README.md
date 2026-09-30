# AWS Service Deep-Dive: Virtual Private Cloud (VPC)

Comprehensive networking reference covering isolated cloud network topologies, Classless Inter-Domain Routing (CIDR) design, subnet partitioning, gateway routing, and packet filtering defense-in-depth on Amazon Web Services.

---

## 1. VPC Multi-Tier Network Architecture

<img width="6261" height="2180" alt="VPC Multi-Tier Isolated Cloud Network Architecture" src="https://github.com/user-attachments/assets/066bc9de-bcb8-45e5-a0a4-52f6b617e5a7" />

---

## 2. Core VPC Networking Components

### 2.1 CIDR Blocks (Classless Inter-Domain Routing)
Defines the private IP address range for the VPC using prefix notation (e.g. `10.0.0.0/16` provides 65,536 IPv4 addresses). Subnets subdivide this block (e.g. `/24` gives 256 addresses, minus 5 reserved by AWS for network, router, DNS, future use, and broadcast).

### 2.2 Public vs Private Subnets
- **Public Subnet:** Its associated Route Table contains an explicit default route (`0.0.0.0/0`) directed to an **Internet Gateway (IGW)**. Resources receive public IPv4 addresses and can receive inbound internet traffic.
- **Private Subnet:** Its Route Table does NOT route directly to an IGW. Inbound internet traffic is completely blocked. Outbound access (e.g. for package updates) is routed through a **NAT Gateway** located in a public subnet.

### 2.3 Route Tables
A set of rules (routes) that determine where network traffic from your subnet or gateway is directed:
- Local route (e.g. `10.0.0.0/16 -> local`): Enables communication between all subnets inside the VPC.
- Default route (`0.0.0.0/0 -> igw-xxx` or `nat-xxx`): Directs external traffic to the appropriate gateway.

### 2.4 Internet Gateway (IGW) vs NAT Gateway
- **Internet Gateway:** Horizontally scaled, redundant, highly available VPC component that enables communication between VPC resources and the internet. Performs Network Address Translation (1-to-1 NAT) for instances with public IPs.
- **NAT Gateway:** Managed service residing in a public subnet that enables instances in a private subnet to initiate outbound IPv4 connections to the internet while preventing external hosts from initiating connections into the private instances.

---

## 3. Defense-in-Depth: Security Groups vs Network ACLs

<img width="5640" height="725" alt="Network ACL vs Security Group Defense in Depth" src="https://github.com/user-attachments/assets/866f1b39-59ce-4cac-801b-9f55e0f9bf84" />

| Feature | Network ACL (NACL) | Security Group (SG) |
| :--- | :--- | :--- |
| **Operating Layer** | Subnet level | Instance / ENI level |
| **State Tracking** | **Stateless:** Return traffic must be explicitly allowed | **Stateful:** Inbound reply traffic is automatically allowed |
| **Rule Types** | Supports both **ALLOW** and **DENY** rules | Supports **ALLOW** rules only |
| **Evaluation Order** | Rules evaluated in numerical order (lowest first) | All rules evaluated simultaneously before making a decision |
| **Default Configuration** | Default NACL allows all inbound and outbound traffic | Default SG allows no inbound, all outbound |

---

## 4. Best Practices for Production VPC Topologies

1. **Deploy Across Multiple Availability Zones:** Provision subnets in at least two AZs for high availability and automated disaster recovery.
2. **Isolate Database Subnets:** Keep databases in private subnets with no route to the Internet Gateway or NAT Gateway. Only allow traffic from application tier security groups.
3. **Use VPC Endpoints (AWS PrivateLink):** Connect privately to AWS services like S3 and DynamoDB without routing through public NAT Gateways, reducing data transfer costs and latency.
