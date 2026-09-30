# ------------------------------------------------------------------------------
# 1. Custom VPC and Network Topology
# ------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "Public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# 2. Security Group Configuration
# ------------------------------------------------------------------------------

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow inbound HTTP and SSH traffic with egress to all"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH ingress for administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound internet traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ------------------------------------------------------------------------------
# 3. Secure S3 Storage Bucket
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "app_storage" {
  bucket_prefix = "${var.bucket_prefix}-"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-storage"
  }
}

resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage_encryption" {
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 4. Compute Engine (EC2 Instance)
# ------------------------------------------------------------------------------

# data "aws_ami" "ubuntu" {
#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   owners = ["099720109477"] # Canonical
# }

resource "aws_instance" "web_server" {
  ami                    = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 LTS
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User data script bootstraps web server and renders cloud telemetry dashboard
  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y nginx

              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "local-instance")
              AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "${var.availability_zone}")

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Terraform Cloud Architecture</title>
                <style>
                  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; }
                  .card { background: #1e293b; border-radius: 12px; padding: 24px; max-width: 600px; margin: 0 auto; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.5); }
                  h1 { color: #38bdf8; margin-top: 0; }
                  .meta { background: #334155; padding: 12px; border-radius: 8px; font-family: monospace; margin: 16px 0; }
                  .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; background: #22c55e; color: #000; }
                </style>
              </head>
              <body>
                <div class="card">
                  <h1>Terraform Cloud Architecture</h1>
                  <span class="badge">PROVISIONED & ACTIVE</span>
                  <div class="meta">
                    <p><strong>Environment:</strong> ${var.environment}</p>
                    <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
                    <p><strong>Availability Zone:</strong> $AZ</p>
                    <p><strong>Storage Bucket:</strong> ${aws_s3_bucket.app_storage.id}</p>
                  </div>
                  <p>Deployed via HashiCorp Terraform AWS Provider.</p>
                </div>
              </body>
              </html>
              HTML

              systemctl restart nginx
              systemctl enable nginx
              EOF

  # Explicit dependency demonstration: Instance depends on Internet Gateway and S3 Bucket
  depends_on = [
    aws_internet_gateway.gw,
    aws_s3_bucket.app_storage
  ]

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
