# Terraform Deployment

This directory provides a reproducible infrastructure-as-code reference for the Enterprise Cloud Security Monitoring Platform.

## What It Creates

| Layer | Terraform resources |
|---|---|
| Network | VPC, two public lab subnets, route table, Internet Gateway |
| Perimeter | Application Load Balancer and regional AWS WAF web ACL |
| Compute | Two Ubuntu web instances and one Ubuntu Splunk instance |
| Access control | Separate ALB, web and SIEM security groups |
| AWS audit | Multi-Region CloudTrail with log-file validation |
| CloudTrail transport | Encrypted S3 bucket, S3 notification and encrypted SQS queue |
| Network telemetry | VPC Flow Logs delivered to CloudWatch Logs |
| Web telemetry | AWS WAF logs delivered to CloudWatch Logs |
| Identity | Least-privilege EC2 role for Splunk AWS log collection |

## Security Decisions

- IMDSv2 is required on every EC2 instance.
- EBS volumes are encrypted.
- The CloudTrail bucket blocks public access, uses encryption and denies insecure transport.
- Splunk uses an EC2 IAM role instead of hard-coded AWS access keys.
- SSH, Splunk Web and the Splunk management API are restricted to `admin_cidr`.
- Web-server port 80 accepts traffic only from the ALB security group.
- Splunk forwarding port 9997 accepts traffic only from the web-server security group.
- WAF runs the AWS Common Rule Set in count mode for safe tuning.
- WAF logs redact the `Authorization` and `Cookie` headers.
- DVWA is not installed automatically.

## Lab Boundary

The design intentionally uses public lab subnets so short-lived instances can install packages without a NAT Gateway. Instance services remain restricted by security groups, but this is not the preferred production network model.

A production deployment should use private application and SIEM subnets, controlled egress, Systems Manager, TLS listeners, secrets management, centralized state locking, backups and separate AWS accounts.

## Prerequisites

- Terraform 1.6 or later
- AWS CLI credentials for an authorized lab account
- Permission to create VPC, EC2, ELB, WAF, CloudTrail, S3, SQS, IAM and CloudWatch resources
- An optional existing EC2 key pair
- A trusted administrator public IP in `/32` notation

## Configure

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit at minimum:

```hcl
admin_cidr = "YOUR.PUBLIC.IP.ADDRESS/32"
key_name   = "YOUR-EXISTING-KEY-PAIR"
```

Never use `0.0.0.0/0` for `admin_cidr`, and never commit `terraform.tfvars`.

## Validate Before Deployment

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=soc-lab.tfplan
```

Review every planned resource and cost before applying:

```bash
terraform apply soc-lab.tfplan
```

Terraform creates infrastructure only. Install and configure DVWA, Splunk Enterprise and Splunk Universal Forwarders manually by following their licensing and security requirements.

## Splunk AWS Integration

The Splunk EC2 instance receives an IAM role with access to:

- Read the project CloudTrail bucket
- Consume the project CloudTrail SQS queue
- Read CloudWatch Logs
- Read CloudTrail configuration
- Discover EC2 and account context

Use the instance role in the Splunk Add-on for AWS. Do not create or store long-lived access keys on the server.

Relevant Terraform outputs:

```text
cloudtrail_bucket_name
cloudtrail_sqs_queue_url
waf_log_group_name
vpc_flow_log_group_name
splunk_instance_role
```

## Cost Controls

This configuration can incur charges for:

- Application Load Balancer
- AWS WAF
- EC2 and EBS
- CloudWatch Logs ingestion and retention
- CloudTrail data and S3 storage
- Public IPv4 addresses

Use short test windows, monitor AWS Billing and destroy resources when the lab is not required.

## Destroy

Before destruction, export any evidence required for the project:

```bash
terraform plan -destroy
terraform destroy
```

The CloudTrail bucket uses `force_destroy = true` for repeatable lab teardown. Do not use that setting for production evidence storage.

## Known Limitations

- No remote state backend is configured.
- No HTTPS listener or ACM certificate is created.
- No NAT Gateway or private application subnet is created.
- Splunk clustering, backups and high availability are outside the lab scope.
- GuardDuty is intentionally not included in this project version.
- Application and SIEM software installation remains manual.

## Recommended CI Checks

Run these checks on every Terraform change:

```bash
terraform fmt -check -recursive
terraform validate
tflint --recursive
trivy config terraform/
```

Deployments should require manual approval and short-lived AWS credentials.
