# Splunk Detection Engineering Library

This directory contains ten custom Splunk Search Processing Language (SPL) detections developed for the Enterprise Cloud Security Monitoring Platform. The rules cover Linux authentication, web application attacks, AWS identity activity, CloudTrail defense evasion, security-group exposure, and AWS WAF matches.

The searches are designed for the project’s current indexes and sourcetypes. Thresholds and lookback windows are intentionally sized for a lab environment and must be baselined before production use.

## Data Requirements

| Splunk index | Sourcetype | Security telemetry |
|---|---|---|
| `linux` | `linux_secure` | SSH authentication events from both Ubuntu web servers |
| `web` | `access_combined` | Apache HTTP access logs from both DVWA web servers |
| `cloudtrail` | `aws:cloudtrail` | AWS API, IAM, and control-plane activity |
| `waf` | `aws:cloudwatchlogs` | AWS WAF request and managed-rule match events |

VPC Flow Logs are not required by these ten rules. Their continuous Splunk input is paused in this lab to control ingestion volume and can be enabled for focused network investigations.

## Rule Catalog

| ID | Detection | Data source | Default severity | MITRE ATT&CK | SPL |
|---|---|---|---|---|---|
| DET-001 | SSH Brute Force | Linux authentication | Medium–Critical | [T1110 – Brute Force](https://attack.mitre.org/techniques/T1110/) | [View rule](DET-001-ssh-brute-force.spl) |
| DET-002 | SQL Injection Attempt | Apache access | Medium–Critical | [T1190 – Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/) | [View rule](DET-002-sql-injection.spl) |
| DET-003 | Cross-Site Scripting Attempt | Apache access | Medium–Critical | [T1190 – Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/) | [View rule](DET-003-xss-attempt.spl) |
| DET-004 | Potential IAM Privilege Escalation | CloudTrail | Medium–Critical | [T1098 – Account Manipulation](https://attack.mitre.org/techniques/T1098/) | [View rule](DET-004-iam-privilege-escalation.spl) |
| DET-005 | CloudTrail Logging Modified or Disabled | CloudTrail | Medium–Critical | [T1562.008 – Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/) | [View rule](DET-005-cloudtrail-tampering.spl) |
| DET-006 | Security Group Opened to the Internet | CloudTrail | Medium–Critical | [T1562.007 – Disable or Modify System Firewall](https://attack.mitre.org/techniques/T1562/007/) | [View rule](DET-006-public-security-group.spl) |
| DET-007 | Repeated AWS WAF Rule Matches | AWS WAF | Low–High | [T1190 – Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/) | [View rule](DET-007-repeated-waf-matches.spl) |
| DET-008 | Directory Traversal Attempt | Apache access | Medium–Critical | [T1190 – Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/) | [View rule](DET-008-directory-traversal.spl) |
| DET-009 | Web Reconnaissance and Enumeration | Apache access | Medium–High | [T1595 – Active Scanning](https://attack.mitre.org/techniques/T1595/) | [View rule](DET-009-web-reconnaissance.spl) |
| DET-010 | Successful SSH Login Following Multiple Failures | Linux authentication | High | [T1110 – Brute Force](https://attack.mitre.org/techniques/T1110/) | [View rule](DET-010-successful-ssh-after-failures.spl) |

## Standard Detection Output

Where applicable, the searches normalize results into a common set of investigation fields:

| Field | Purpose |
|---|---|
| `detection_id` | Stable identifier used in documentation and alert tracking |
| `detection` | Human-readable security use case |
| `severity` | Initial risk level assigned by the detection logic |
| `source_ip` | Originating address associated with the activity |
| `affected_hosts` or `host` | System or application receiving the activity |
| `last_seen` | Most recent matching event |
| `mitre_technique` | MITRE ATT&CK technique associated with the behavior |
| `evidence` | Relevant requests, paths, rules, or event details |

Severity is a triage aid, not a final incident classification. An analyst should validate asset criticality, user context, success or failure, exposure, and related events before escalating.

## Recommended Scheduling

| Rule group | Suggested schedule | Search window | Suggested suppression |
|---|---|---|---|
| DET-001–DET-009 | Every 5 minutes | Last 15 minutes | 15–30 minutes by source IP and detection ID |
| DET-010 | Every 15 minutes | Last 24 hours | 60 minutes by source IP and host |

Overlapping windows reduce the chance of missing events that arrive late. Suppression should be configured carefully so repeated or escalating activity remains visible.

## Deployment in Splunk

For each detection:

1. Open **Search & Reporting** in Splunk.
2. Copy the contents of the required `.spl` file into the search bar.
3. Run the search using **All time** in the UI because the SPL already defines its own lookback window.
4. Confirm that the expected index, sourcetype, and extracted fields are present.
5. Tune thresholds against normal activity.
6. Select **Save As → Alert**.
7. Configure the schedule, trigger condition, suppression, ownership, and permissions.
8. Add an approved notification action if required.

No rule in this repository performs automated containment. Blocking IP addresses, disabling users, changing IAM policies, or modifying security groups requires analyst approval.

## Validation Approach

| Detection | Validation method |
|---|---|
| DET-001 | Controlled invalid-user SSH attempts against the lab web servers |
| DET-002 | Encoded SQL injection request sent to DVWA through the ALB |
| DET-003 | Encoded reflected-XSS request sent to DVWA through the ALB |
| DET-004 | Detection logic and available IAM audit events reviewed |
| DET-005 | Non-persistent synthetic logic test; CloudTrail was not disabled |
| DET-006 | Non-persistent synthetic logic test; no unsafe public exposure was created |
| DET-007 | Repeated authorized requests that matched AWS WAF managed rules |
| DET-008 | Encoded traversal request sent to DVWA through the ALB |
| DET-009 | Requests to multiple commonly enumerated web paths |
| DET-010 | Failed SSH attempts followed by an authorized key-based login from the same source |

All attack simulations must be performed only against systems that you own or are explicitly authorized to test.

## Detection Validation

Detailed testing methods, results, limitations, false-positive considerations, and tuning recommendations are available in the:

➡️ [Detection Validation Report](../docs/detection-validation.md)


## Expected Zero-Result Searches

A search returning no events does not automatically mean that the rule is broken.

- **DET-004** returns results only when one of the selected IAM administrative actions appears in CloudTrail.
- **DET-005** returns results only when CloudTrail configuration or logging is modified.
- **DET-006** returns results only when an ingress rule allows `0.0.0.0/0` or `::/0`.
- Threshold-based rules return no rows until their minimum count is reached.
- Delayed AWS or forwarder ingestion can place events outside a short search window.

When troubleshooting, temporarily increase the lookback period, remove the final threshold, and inspect raw field extraction before changing the production rule.

## Production Tuning Guidance

Before production deployment:

- Replace lab thresholds with values based on historical baselines.
- Maintain allowlists for approved scanners, administrators, automation roles, NAT gateways, and monitoring systems.
- Add asset criticality and identity context.
- Enrich public IP addresses with approved threat-intelligence sources.
- Separate unsuccessful probes from successful compromise indicators.
- Use risk-based alerting or correlation searches to combine related behavior.
- Add service-account and expected-region exceptions only after documented review.
- Test alert suppression to prevent duplicate incidents without hiding continued attacks.
- Monitor ingestion delay and sourcetype health.
- Review MITRE mappings and detection logic after significant AWS, application, or logging changes.

## Limitations

- The searches use fields and sourcetypes available in this lab; other Splunk deployments may require field-name changes.
- Apache request detections identify suspicious patterns but do not prove exploitation.
- WAF count-mode matches indicate inspection-rule activity, not necessarily blocked traffic.
- A shared NAT address may represent multiple systems or users.
- DET-010 correlates authentication outcomes by source IP and host; additional identity and session context is recommended in production.
- CloudTrail management events may be delayed by the S3, SQS, and Splunk ingestion pipeline.

## Change Control

When modifying a rule, document:

- Reason for the change
- Previous and new thresholds
- Test evidence
- Expected false-positive impact
- Reviewer or approver
- Deployment date

This preserves detection-engineering traceability and makes future tuning decisions easier to review.
