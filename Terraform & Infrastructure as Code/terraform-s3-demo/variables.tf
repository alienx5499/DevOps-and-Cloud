variable "aws_region" {
  description = "The target AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Prefix for the globally unique S3 bucket name"
  type        = string
  default     = "sst-devops-storage"
}

variable "environment" {
  description = "Deployment lifecycle environment name"
  type        = string
  default     = "staging"
}

variable "versioning_enabled" {
  description = "State flag to enable object versioning"
  type        = bool
  default     = true
}
