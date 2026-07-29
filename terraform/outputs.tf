output "alb_dns_name" {
  description = "Public ALB DNS name protected by the regional WAF web ACL."
  value       = aws_lb.web.dns_name
}

output "splunk_web_url" {
  description = "Restricted Splunk Web URL. Access is limited to admin_cidr."
  value       = "http://${aws_instance.siem.public_ip}:8000"
}

output "splunk_instance_role" {
  description = "IAM role used by the Splunk EC2 instance instead of long-lived access keys."
  value       = aws_iam_role.splunk.name
}

output "web_private_ips" {
  description = "Private addresses of the web targets."
  value       = aws_instance.web[*].private_ip
}

output "web_public_ips" {
  description = "Temporary public addresses used for controlled lab administration."
  value       = aws_instance.web[*].public_ip
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket containing CloudTrail files."
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_sqs_queue_url" {
  description = "SQS queue URL consumed by the Splunk Add-on for AWS."
  value       = aws_sqs_queue.cloudtrail.id
}

output "waf_log_group_name" {
  description = "CloudWatch Logs group receiving AWS WAF request logs."
  value       = aws_cloudwatch_log_group.waf.name
}

output "vpc_flow_log_group_name" {
  description = "CloudWatch Logs group receiving VPC Flow Logs."
  value       = aws_cloudwatch_log_group.vpc_flow.name
}
