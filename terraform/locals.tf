locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  short_name_prefix  = trimsuffix(substr("${var.project_name}-${var.environment}", 0, 24), "-")
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Authorized cloud security monitoring lab"
      DataClass   = "SecurityTelemetry"
    },
    var.extra_tags
  )
}
