output "bucket_name" {
  description = "The globally unique name of the created S3 bucket"
  value       = aws_s3_bucket.demo_bucket.id
}

output "bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the bucket"
  value       = aws_s3_bucket.demo_bucket.arn
}

output "bucket_region" {
  description = "The AWS region where the bucket resides"
  value       = aws_s3_bucket.demo_bucket.region
}

output "versioning_status" {
  description = "Current versioning status configuration"
  value       = aws_s3_bucket_versioning.demo_versioning.versioning_configuration[0].status
}
