#!/usr/bin/env bash
set -euo pipefail

HOSTNAME_VALUE="${hostname}"

hostnamectl set-hostname "$HOSTNAME_VALUE"
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl jq tar unzip

install -d -m 0750 /opt/soc-bootstrap

cat > /opt/soc-bootstrap/README.txt <<'TEXT'
This instance was provisioned for an authorized Splunk lab.

Splunk Enterprise is intentionally not installed automatically because its
download and license terms require an authorized package and user acceptance.

After installing Splunk:
1. Enable the receiving port 9997.
2. Restrict Splunk Web and the management API to the trusted administrator CIDR.
3. Install the Splunk Add-on for AWS.
4. Use the attached EC2 IAM role instead of long-lived access keys.
5. Configure the CloudTrail SQS input, WAF CloudWatch input, and VPC Flow input.
TEXT
