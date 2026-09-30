variable "aws_region" {
  description = "The AWS region where resources will be provisioned"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier for resource naming and tagging"
  type        = string
  default     = "cloud-in-action"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, production)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Target Availability Zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance microarchitecture size"
  type        = string
  default     = "t3.micro"
}

variable "bucket_prefix" {
  description = "Prefix for the globally unique S3 bucket name"
  type        = string
  default     = "sst-cloud-action"
}
