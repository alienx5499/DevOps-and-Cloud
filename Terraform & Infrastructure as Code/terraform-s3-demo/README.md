# Task 1: Terraform S3 Bucket Lifecycle & State Management

Hands-on automation laboratory implementing cloud infrastructure provisioning using HashiCorp Terraform. Covers the complete declarative lifecycle workflow: initialization, code formatting, semantic validation, execution planning, state convergence, output inspection, and automated resource destruction.

---

## 1. Terraform Core Workflow

<img width="7560" height="830" alt="Terraform Declarative Resource Lifecycle Flow" src="https://github.com/user-attachments/assets/87c998f0-f8de-44c7-9aa8-1a65c63c37bf" />

---

## 2. Step-by-Step Hands-on Execution

Navigate to the project directory:
```bash
cd terraform-s3-demo
```

---

### Step 1: Initialize Working Directory (terraform init)
Downloads the required HashiCorp AWS and Random provider plugins into `.terraform/` and locks versions in `.terraform.lock.hcl`:
```bash
terraform init
```

Expected Terminal Output:
```text
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding hashicorp/random versions matching "~> 3.5"...
- Installing hashicorp/aws v5.69.0...
- Installed hashicorp/aws v5.69.0 (signed by HashiCorp)
- Installing hashicorp/random v3.6.3...
- Installed hashicorp/random v3.6.3 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.
```

<img src="https://github.com/user-attachments/assets/e5945cbb-6aad-42ea-a759-080b1f228292" alt="terraform init execution output" width="100%" />

---

### Step 2: Format HCL Code (terraform fmt)
Rewrites Terraform configuration files to the canonical format and style:
```bash
terraform fmt
```

Expected Terminal Output:
```text
main.tf
provider.tf
variables.tf
outputs.tf
terraform.tfvars
```

<img src="https://github.com/user-attachments/assets/95121202-7bd7-4b9d-aded-cb1f6373f1c6" alt="terraform fmt execution output" width="100%" />

---

### Step 3: Validate Syntax (terraform validate)
Verifies whether the configuration files are syntactically valid and internally consistent without contacting remote cloud APIs:
```bash
terraform validate
```

Expected Terminal Output:
```text
Success! The configuration is valid.
```

<img src="https://github.com/user-attachments/assets/c13318c9-c9b7-4ba6-9323-51b24c4c8d76" alt="terraform validate execution output" width="100%" />

---

### Step 4: Generate Execution Plan (terraform plan)
Compares the declared configuration against current state (`terraform.tfstate`) and calculates the resource delta:
```bash
terraform plan
```

Expected Terminal Output:
```text
Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.demo_bucket will be created
  + resource "aws_s3_bucket" "demo_bucket" {
      + arn                         = (known after apply)
      + bucket                      = (known after apply)
      + force_destroy               = true
      + id                          = (known after apply)
      + region                      = (known after apply)
      + tags_all                    = {
          + "Environment" = "staging"
          + "ManagedBy"   = "Terraform"
          + "Project"     = "SST-Terraform-Demo"
        }
    }

  # aws_s3_bucket_public_access_block.demo_public_access will be created
  + resource "aws_s3_bucket_public_access_block" "demo_public_access" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + ignore_public_acls      = true
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.demo_encryption will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "demo_encryption" {
      + bucket = (known after apply)
      + rule {
          + apply_server_side_encryption_by_default {
              + sse_algorithm = "AES256"
            }
        }
    }

  # aws_s3_bucket_versioning.demo_versioning will be created
  + resource "aws_s3_bucket_versioning" "demo_versioning" {
      + bucket = (known after apply)
      + versioning_configuration {
          + status = "Enabled"
        }
    }

  # random_id.bucket_suffix will be created
  + resource "random_id" "bucket_suffix" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 4
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn        = (known after apply)
  + bucket_name       = (known after apply)
  + bucket_region     = (known after apply)
  + versioning_status = "Enabled"
```

<img src="https://github.com/user-attachments/assets/fbe64166-5c3f-46fe-98ea-70798531bde6" alt="terraform plan execution output" width="100%" />

---

### Step 5: Apply Changes (terraform apply)
Provisions the S3 bucket, versioning configuration, encryption rule, and public access blocks:
```bash
terraform apply -auto-approve
```

Expected Terminal Output:
```text
random_id.bucket_suffix: Creating...
random_id.bucket_suffix: Creation complete after 0s [id=3a9b1c4e]
aws_s3_bucket.demo_bucket: Creating...
aws_s3_bucket.demo_bucket: Creation complete after 2s [id=sst-termo9-lab-3a9b1c4e]
aws_s3_bucket_public_access_block.demo_public_access: Creating...
aws_s3_bucket_versioning.demo_versioning: Creating...
aws_s3_bucket_server_side_encryption_configuration.demo_encryption: Creating...
aws_s3_bucket_versioning.demo_versioning: Creation complete after 1s
aws_s3_bucket_public_access_block.demo_public_access: Creation complete after 1s
aws_s3_bucket_server_side_encryption_configuration.demo_encryption: Creation complete after 1s

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::sst-termo9-lab-3a9b1c4e"
bucket_name = "sst-termo9-lab-3a9b1c4e"
bucket_region = "us-east-1"
versioning_status = "Enabled"
```

<img src="https://github.com/user-attachments/assets/fee6ee71-f842-41c7-a844-d59a6d63f827" alt="terraform apply execution output" width="100%" />

---

### Step 6: Inspect Live State & Query Outputs (terraform show & output)
```bash
# Display human-readable state summary
terraform show

# Query specific output values
terraform output
terraform output -raw bucket_name && echo ""
```

Expected Terminal Output:
```text
# aws_s3_bucket.demo_bucket:
resource "aws_s3_bucket" "demo_bucket" {
    arn                         = "arn:aws:s3:::sst-termo9-lab-3a9b1c4e"
    bucket                      = "sst-termo9-lab-3a9b1c4e"
    force_destroy               = true
    id                          = "sst-termo9-lab-3a9b1c4e"
    region                      = "us-east-1"
    tags                        = {}
    tags_all                    = {
        "Environment" = "staging"
        "ManagedBy"   = "Terraform"
        "Project"     = "SST-Terraform-Demo"
    }
}

bucket_arn = "arn:aws:s3:::sst-termo9-lab-3a9b1c4e"
bucket_name = "sst-termo9-lab-3a9b1c4e"
bucket_region = "us-east-1"
versioning_status = "Enabled"

sst-termo9-lab-3a9b1c4e
```

<img src="https://github.com/user-attachments/assets/02629bb0-8fef-4f4a-a5a9-7dae88ecd559" alt="terraform show and output verification" width="100%" />

---

### Step 7: Teardown Infrastructure (terraform destroy)
Reverses all changes and deletes all created resources cleanly:
```bash
terraform destroy -auto-approve
```

Expected Terminal Output:
```text
aws_s3_bucket_server_side_encryption_configuration.demo_encryption: Destroying... [id=sst-termo9-lab-3a9b1c4e]
aws_s3_bucket_public_access_block.demo_public_access: Destroying... [id=sst-termo9-lab-3a9b1c4e]
aws_s3_bucket_versioning.demo_versioning: Destroying... [id=sst-termo9-lab-3a9b1c4e]
aws_s3_bucket_versioning.demo_versioning: Destruction complete after 0s
aws_s3_bucket_public_access_block.demo_public_access: Destruction complete after 0s
aws_s3_bucket_server_side_encryption_configuration.demo_encryption: Destruction complete after 0s
aws_s3_bucket.demo_bucket: Destroying... [id=sst-termo9-lab-3a9b1c4e]
aws_s3_bucket.demo_bucket: Destruction complete after 1s
random_id.bucket_suffix: Destroying... [id=3a9b1c4e]
random_id.bucket_suffix: Destruction complete after 0s

Destroy complete! Resources: 5 destroyed.
```

<img src="https://github.com/user-attachments/assets/9e8dc5da-05e7-4d1b-89dd-ea0381b28679" alt="terraform destroy execution output" width="100%" />

---

## 3. Configuration Files Breakdown

| File | Purpose | Key Attributes |
| :--- | :--- | :--- |
| `provider.tf` | Declares required providers & AWS region | `hashicorp/aws ~> 5.0`, `default_tags` |
| `variables.tf` | Defines parameter types, defaults & documentation | `aws_region`, `bucket_prefix`, `environment` |
| `terraform.tfvars` | Supplies environment-specific variable assignments | Explicit values overriding defaults |
| `main.tf` | Declares target AWS resources | S3 bucket, versioning, AES256 SSE, public access block |
| `outputs.tf` | Exposes critical resource attributes | `bucket_name`, `bucket_arn`, `bucket_region` |
