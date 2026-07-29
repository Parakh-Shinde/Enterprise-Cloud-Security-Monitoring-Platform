variable "project_name" {
  description = "Lowercase project identifier used in AWS resource names."
  type        = string
  default     = "enterprise-cloud-security-soc"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.project_name))
    error_message = "project_name must start with a letter and contain 3-32 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.environment))
    error_message = "environment must contain 2-15 lowercase letters, numbers, or hyphens."
  }
}

variable "aws_region" {
  description = "AWS Region for the regional resources."
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR range assigned to the lab VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two subnet CIDRs used by the ALB and lab EC2 instances."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two subnet CIDRs are required."
  }
}

variable "admin_cidr" {
  description = "Trusted administrator public IP in /32 notation. Never use 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid CIDR and cannot be 0.0.0.0/0."
  }
}

variable "alb_ingress_cidrs" {
  description = "CIDRs permitted to reach the public HTTP listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Optional existing EC2 key-pair name for controlled lab administration."
  type        = string
  default     = null
  nullable    = true
}

variable "web_server_count" {
  description = "Number of web instances registered with the target group."
  type        = number
  default     = 2

  validation {
    condition     = var.web_server_count == 2
    error_message = "This reference architecture requires exactly two web servers."
  }
}

variable "web_instance_type" {
  description = "EC2 instance type used by each web server."
  type        = string
  default     = "t3.micro"
}

variable "siem_instance_type" {
  description = "EC2 instance type used by the single-node Splunk lab server."
  type        = string
  default     = "t3.small"
}

variable "web_root_volume_gb" {
  description = "Encrypted gp3 root volume size for web instances."
  type        = number
  default     = 16
}

variable "siem_root_volume_gb" {
  description = "Encrypted gp3 root volume size for the Splunk instance."
  type        = number
  default     = 50
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
  default     = 30
}

variable "cloudtrail_object_retention_days" {
  description = "Days before lab CloudTrail objects expire from S3."
  type        = number
  default     = 90
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection. Keep false for short-lived labs."
  type        = bool
  default     = false
}

variable "extra_tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
