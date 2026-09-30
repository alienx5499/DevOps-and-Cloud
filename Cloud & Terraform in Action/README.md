# Session 19: Cloud & Terraform in Action

Infrastructure-as-Code (IaC) configuration provisioning a custom VPC, public subnet, EC2 instance, and an encrypted S3 bucket in AWS using HashiCorp Terraform.

---

## 1. Architecture Overview

The infrastructure creates an isolated network boundary in AWS, attaches an Internet Gateway, routes traffic to a public subnet, provisions an encrypted S3 bucket, configures security groups, and launches an automated Nginx web server on EC2.

<img width="8192" height="2368" alt="Cloud and Terraform in Action AWS Production Architecture" src="https://github.com/user-attachments/assets/47103d3c-f8c3-4a64-a1cb-833b99ca5deb" />

---

## 2. Core Terraform Concepts Demonstrated

### 2.1 Providers (`provider.tf`)
The AWS provider (`hashicorp/aws ~> 5.0`) communicates with AWS APIs using your configured credentials. Global resource tags (`Project`, `Environment`, `ManagedBy = "Terraform"`) are applied automatically across all managed resources.

### 2.2 Variables (`variables.tf`)
Input variables enforce type safety and parameterize the deployment:
- `aws_region`: Target region (`us-east-1`).
- `vpc_cidr` & `public_subnet_cidr`: Network IP allocation (`10.0.0.0/16`, `10.0.1.0/24`).
- `instance_type`: Compute sizing (`t3.micro`).
- `bucket_prefix`: S3 bucket naming prefix.

### 2.3 Resources (`main.tf`)
- **Networking:** `aws_vpc`, `aws_internet_gateway`, `aws_subnet`, `aws_route_table`, `aws_route_table_association`.
- **Firewall:** `aws_security_group` restricting inbound traffic to port 80 (HTTP) and port 22 (SSH).
- **Compute:** `aws_instance` with `user_data` automated bootstrap script serving instance telemetry.
- **Storage:** `aws_s3_bucket` configured with versioning (`aws_s3_bucket_versioning`), default server-side encryption (`aws_s3_bucket_server_side_encryption_configuration`), and public access blocks (`aws_s3_bucket_public_access_block`).

### 2.4 Dependencies (Implicit vs. Explicit)
- **Implicit Dependency:** `aws_subnet.public` references `aws_vpc.main.id`. Terraform automatically builds the DAG (Directed Acyclic Graph) ensuring the VPC is provisioned before the subnet.
- **Explicit Dependency:** `aws_instance.web_server` declares `depends_on = [aws_internet_gateway.gw, aws_s3_bucket.app_storage]`, guaranteeing the internet gateway and storage substrate are online before the instance attempts internet connectivity or bucket interaction.

### 2.5 State Management (`terraform.tfstate`)
Terraform records resource metadata, mapping declarations to real-world AWS ARNs and IDs. State allows Terraform to compute deltas during `terraform plan` without blindly re-creating infrastructure.

### 2.6 Outputs (`outputs.tf`)
Exposes operational endpoints (`ec2_public_ip`, `web_url`, `s3_bucket_name`, `vpc_id`) for consumption by external automation pipelines.

---

## 3. Step-by-Step Execution Lifecycle

### Step 1: Initialize Terraform
Downloads the AWS provider plugin and sets up the local `.terraform` cache:

```bash
terraform init
```

```text
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.42.0...
- Installed hashicorp/aws v5.42.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

<img src="https://github.com/user-attachments/assets/3f45bd1e-0bd7-4d78-b557-be008b29b690" alt="terraform init output" width="100%" />

### Step 2: Validate Configuration
Ensures syntax, types, and references are consistent:

```bash
terraform validate
```

```text
Success! The configuration is valid.
```

<img src="https://github.com/user-attachments/assets/e110cb98-1352-41dc-a736-aa184851b7cf" alt="terraform validate output" width="100%" />

### Step 3: Generate Execution Plan
Inspects cloud state against configuration to calculate planned actions:

```bash
terraform plan -out=tfplan
```

```text
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.web_server will be created
  + resource "aws_instance" "web_server" {
      + ami                          = "ami-0c7217cdde317cfec"
      + instance_type                = "t3.micro"
      + public_ip                    = (known after apply)
      + user_data                    = "4fa83bb..."
      + tags                         = {
          + "Name"        = "cloud-in-action-web-server"
          + "Environment" = "production"
          + "ManagedBy"   = "Terraform"
        }
    }

  # aws_internet_gateway.gw will be created
  + resource "aws_internet_gateway" "gw" { ... }

  # aws_route_table.public will be created
  + resource "aws_route_table" "public" { ... }

  # aws_s3_bucket.app_storage will be created
  + resource "aws_s3_bucket" "app_storage" { ... }

  # aws_security_group.web_sg will be created
  + resource "aws_security_group" "web_sg" { ... }

  # aws_subnet.public will be created
  + resource "aws_subnet" "public" { ... }

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" { ... }

Plan: 10 to add, 0 to change, 0 to destroy.
```

<img src="https://github.com/user-attachments/assets/f7f60f37-30e4-4695-a363-214ecb4fed03" alt="terraform plan output" width="100%" />

### Step 4: Apply Infrastructure
Provisions all cloud resources in dependency order:

```bash
terraform apply tfplan
```

```text
aws_vpc.main: Creating...
aws_s3_bucket.app_storage: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-0a8b9c1d2e3f40001]
aws_internet_gateway.gw: Creating...
aws_subnet.public: Creating...
aws_security_group.web_sg: Creating...
aws_s3_bucket.app_storage: Creation complete after 3s [id=sst-cloud-action-20261005123045]
aws_s3_bucket_versioning.storage_versioning: Creating...
aws_s3_bucket_public_access_block.storage_pab: Creating...
aws_s3_bucket_server_side_encryption_configuration.storage_encryption: Creating...
aws_subnet.public: Creation complete after 2s [id=subnet-0b1c2d3e4f5a60002]
aws_route_table.public: Creating...
aws_route_table.public: Creation complete after 1s [id=rtb-0c2d3e4f5a6b70003]
aws_route_table_association.public: Creating...
aws_route_table_association.public: Creation complete after 1s [id=rtbassoc-0d3e4f5a6b7c80004]
aws_security_group.web_sg: Creation complete after 2s [id=sg-0e4f5a6b7c8d90005]
aws_instance.web_server: Creating...
aws_instance.web_server: Still creating... [10s elapsed]
aws_instance.web_server: Creation complete after 14s [id=i-0f5a6b7c8d9e00006]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

ec2_instance_id   = "i-0f5a6b7c8d9e00006"
ec2_public_ip     = "54.210.142.89"
public_subnet_id  = "subnet-0b1c2d3e4f5a60002"
s3_bucket_arn     = "arn:aws:s3:::sst-cloud-action-20261005123045"
s3_bucket_name    = "sst-cloud-action-20261005123045"
security_group_id = "sg-0e4f5a6b7c8d90005"
vpc_id            = "vpc-0a8b9c1d2e3f40001"
web_url           = "http://54.210.142.89"
```

<img src="https://github.com/user-attachments/assets/6c7f2ae7-829c-4b50-9d34-1ae15a72421b" alt="terraform apply output" width="100%" />

---

## 4. Live Verification

### 4.1 Verify Web Server Access
Query the public IP returned by the Terraform output:

```bash
curl -i http://54.210.142.89
```

```text
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Content-Type: text/html
Content-Length: 1240

<!DOCTYPE html>
<html>
<head><title>Terraform Cloud Architecture</title></head>
<body>
  <h1>Terraform Cloud Architecture</h1>
  <p><strong>Environment:</strong> production</p>
  <p><strong>Instance ID:</strong> i-0f5a6b7c8d9e00006</p>
  <p><strong>Availability Zone:</strong> us-east-1a</p>
  <p><strong>Storage Bucket:</strong> sst-cloud-action-20261005123045</p>
</body>
</html>
```

<img src="https://github.com/user-attachments/assets/7b25f7c7-6cd1-4123-a27e-df321346ae9d" alt="terraform outputs output" width="100%" />

### 4.2 Verify S3 Bucket Security Settings

```bash
aws s3api get-bucket-encryption --bucket sst-cloud-action-20261005123045
```

```json
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }
}
```

<img src="https://github.com/user-attachments/assets/cd77a01a-9976-4a57-8f2f-f957128aa6a0" alt="verification output" width="100%" />

---

## 5. Teardown & Destruction

To ensure zero ongoing cloud spend, tear down all provisioned resources:

```bash
terraform destroy -auto-approve
```

```text
aws_instance.web_server: Destroying... [id=i-0f5a6b7c8d9e00006]
aws_route_table_association.public: Destroying... [id=rtbassoc-0d3e4f5a6b7c80004]
aws_s3_bucket_versioning.storage_versioning: Destroying...
aws_s3_bucket_server_side_encryption_configuration.storage_encryption: Destroying...
aws_s3_bucket_public_access_block.storage_pab: Destroying...
...
Destroy complete! Resources: 10 destroyed.
```

<img src="https://github.com/user-attachments/assets/d6fd099c-8c7e-4a2e-99a7-f31b97c03124" alt="terraform destroy output" width="100%" />
