# Session 18: Terraform & Infrastructure as Code (IaC) with AWS Cloud Services

Declarative cloud resource provisioning using HashiCorp Terraform and architectural reference guides for AWS services (IAM, EC2, S3, VPC, DynamoDB, and RDS).

---

## Student Information

- **Name:** Prabal Patra
- **Enrollment Number:** 24BCS10031

---

## Infrastructure as Code Architecture

<img width="5717" height="3565" alt="Infrastructure as Code Architecture with AWS" src="https://github.com/user-attachments/assets/71fb338b-b789-40c4-95e7-5f110a5f93d5" />

---

## Laboratory Structure & Navigation

| Directory | Module Focus | Key Concepts & Deliverables |
| :--- | :--- | :--- |
| [terraform-s3-demo/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Terraform%20&%20Infrastructure%20as%20Code/terraform-s3-demo/README.md) | Task 1: Terraform Automation | S3 bucket lifecycle: `init`, `fmt`, `validate`, `plan`, `apply`, `show`, `output`, `destroy` |
| [aws-services/01-iam/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Terraform%20&%20Infrastructure%20as%20Code/aws-services/01-iam/README.md) | Task 2.1: IAM Governance | Users, groups, roles, policy evaluation engine, principle of least privilege |
| [aws-services/02-ec2/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Terraform%20&%20Infrastructure%20as%20Code/aws-services/02-ec2/README.md) | Task 2.2: Compute Subsystem | AMIs, instance types, EBS volumes (gp3/io2), Security Groups, lifecycle states |
| [aws-services/03-s3/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Terraform%20&%20Infrastructure%20as%20Code/aws-services/03-s3/README.md) | Task 2.3: Object Storage | Buckets, storage classes (Standard to Glacier Deep Archive), lifecycle transitions, encryption |
| [aws-services/04-vpc/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Terraform%20&%20Infrastructure%20as%20Code/aws-services/04-vpc/README.md) | Task 2.4: Cloud Networking | Multi-tier VPC, CIDR partitioning, public vs private subnets, IGW vs NAT, Security Groups vs NACLs |
| [aws-services/05-dynamodb-rds/](file:///Users/prabalpatra/Developer/SST/SST%20Term%209/DevOps%20%26%20Cloud%20%5BSWE%5D/Terraform%20&%20Infrastructure%20as%20Code/aws-services/05-dynamodb-rds/README.md) | Task 2.5: Managed Databases | NoSQL key-value (DynamoDB) vs Relational (RDS Multi-AZ, Read Replicas, Point-in-time recovery) |

---

## Key Takeaways

1. **Declarative state convergence:** Terraform maintains an explicit state file (`terraform.tfstate`) representing real cloud infrastructure. Running `terraform plan` safely computes diffs before making irreversible API calls.
2. **Shift-left cloud governance:** Managing infrastructure as code allows peer code reviews, automated security linting (Checkov, tfsec), and deterministic multi-environment rollouts.
3. **AWS security defense-in-depth:** Combining least-privilege IAM roles, private VPC subnet isolation, stateful security groups, and default encryption at rest ensures enterprise-grade cloud reliability.
