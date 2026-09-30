output "vpc_id" {
  description = "Unique identifier of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Identifier of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Identifier of the web security group"
  value       = aws_security_group.web_sg.id
}

output "ec2_instance_id" {
  description = "Identifier of the web server EC2 instance"
  value       = aws_instance.web_server.id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "web_url" {
  description = "Direct HTTP access URL for the provisioned web application"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "s3_bucket_name" {
  description = "Globally unique name of the S3 storage bucket"
  value       = aws_s3_bucket.app_storage.id
}

output "s3_bucket_arn" {
  description = "Amazon Resource Name (ARN) of the storage bucket"
  value       = aws_s3_bucket.app_storage.arn
}
