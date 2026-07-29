resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public HTTP entry point for the lab ALB"
  vpc_id      = aws_vpc.soc.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Web instances accept HTTP only from the ALB and SSH from the administrator"
  vpc_id      = aws_vpc.soc.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

resource "aws_security_group" "siem" {
  name        = "${local.name_prefix}-siem-sg"
  description = "Splunk management and forwarding traffic"
  vpc_id      = aws_vpc.soc.id

  tags = {
    Name = "${local.name_prefix}-siem-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Public HTTP through AWS WAF and ALB"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB traffic to the registered web targets"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from the ALB security group"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh_admin" {
  security_group_id = aws_security_group.web.id
  description       = "Restricted SSH administration"
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Lab package installation and outbound telemetry"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "siem_ssh_admin" {
  security_group_id = aws_security_group.siem.id
  description       = "Restricted Splunk server SSH administration"
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "siem_web_admin" {
  security_group_id = aws_security_group.siem.id
  description       = "Restricted Splunk Web access"
  cidr_ipv4         = var.admin_cidr
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "siem_management_admin" {
  security_group_id = aws_security_group.siem.id
  description       = "Restricted Splunk management API access"
  cidr_ipv4         = var.admin_cidr
  from_port         = 8089
  to_port           = 8089
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "siem_forwarder" {
  security_group_id            = aws_security_group.siem.id
  description                  = "Splunk Universal Forwarder ingestion"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 9997
  to_port                      = 9997
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "siem_all" {
  security_group_id = aws_security_group.siem.id
  description       = "AWS API access, updates, and analyst integrations"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
