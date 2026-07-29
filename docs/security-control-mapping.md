# Security Control Mapping

## Purpose

This document maps the security capabilities implemented in the Enterprise Cloud Security Monitoring Platform to recognized cybersecurity frameworks.

The mapping demonstrates how the technical controls, telemetry sources, detection rules, dashboards, and incident-response procedures support broader security outcomes.

## Frameworks Covered

- NIST Cybersecurity Framework 2.0
- CIS Critical Security Controls
- CIS Amazon Web Services Foundations guidance
- MITRE ATT&CK Enterprise

> **Important:** This is a lab-level control mapping for educational and portfolio purposes. It is not a certification, compliance assessment, audit opinion, or claim of complete framework implementation.

---

## Implemented Security Capabilities

| Capability | Implementation | Evidence |
|---|---|---|
| Centralized security monitoring | Splunk Enterprise receives AWS, Linux, Apache and WAF telemetry | SOC dashboard and index-health searches |
| AWS audit logging | Multi-Region CloudTrail events delivered through S3 and SQS | `index=cloudtrail`, `aws:cloudtrail` |
| Identity monitoring | CloudTrail and Linux authentication detections | DET-001, DET-004 and DET-010 |
| Web threat monitoring | Apache access logs and AWS WAF logs | DET-002, DET-003, DET-007, DET-008 and DET-009 |
| Network visibility | VPC Flow Logs delivered to CloudWatch Logs | Historical `vpcflow` evidence |
| Infrastructure security | Terraform security controls and automated Checkov scanning | Terraform CI workflow |
| Detection as code | Ten SPL detections validated through Python and GitHub Actions | Detection Quality Checks workflow |
| Incident response | Analyst-controlled triage, evidence and response procedures | Incident Response Runbook |
| Threat modelling | STRIDE-based threats, trust boundaries and attack paths | Threat Model document |
| Validation evidence | Detection tests, screenshots and limitations | Detection Validation Report |

---

# NIST Cybersecurity Framework 2.0 Mapping

NIST CSF 2.0 organizes cybersecurity outcomes into six Functions: Govern, Identify, Protect, Detect, Respond and Recover.

| CSF Function | Security outcome | Project implementation | Status |
|---|---|---|---|
| Govern | Establish cybersecurity risk-management expectations and responsibilities | Documented architecture, risk assessment, security limitations, response approval requirements and project scope | Partially implemented |
| Identify | Understand assets, identities, data sources, dependencies and risks | Documented EC2 instances, ALB, WAF, IAM roles, CloudTrail, Splunk indexes, trust boundaries and data flows | Implemented for lab |
| Protect | Apply safeguards to reduce the likelihood and impact of compromise | Security groups, IAM roles, IMDSv2, encrypted storage, S3 public-access protection, WAF managed rules and restricted administration | Partially implemented |
| Detect | Discover and analyze potentially malicious activity | Splunk ingestion, dashboards, log-source health monitoring and ten SPL detections | Implemented |
| Respond | Contain, communicate, investigate and manage detected incidents | Incident Response Runbook, investigation workflow, severity model, evidence checklist and analyst-controlled containment | Implemented as documented process |
| Recover | Restore services, verify controls and improve security after an incident | Recovery-validation checklist, rollback expectations, lessons learned and detection-tuning process | Implemented as documented process |

---

## NIST CSF Control Evidence

| Security activity | Project evidence |
|---|---|
| Cybersecurity risk documentation | `README.md` security risk assessment |
| Asset and architecture identification | `architecture/` |
| Threat and trust-boundary analysis | `docs/threat-model.md` |
| Protective infrastructure configuration | `terraform/` |
| Continuous monitoring | Splunk Dashboard Studio dashboard |
| Detection development | `detections/DET-001` through `DET-010` |
| Detection validation | `docs/detection-validation.md` |
| Incident analysis | `docs/incident-case-study.md` |
| Response procedures | `docs/incident-response-runbook.md` |
| Automated quality assurance | `.github/workflows/` |

---

# CIS Critical Security Controls Mapping

This mapping is performed at the control-domain level. Exact safeguard applicability depends on the selected CIS Controls version, implementation group and organizational environment.

| CIS control domain | Project implementation | Coverage |
|---|---|---|
| Inventory and Control of Enterprise Assets | AWS resources, EC2 instances, ALB, subnets and security components are documented | Partial |
| Inventory and Control of Software Assets | Apache, DVWA, Splunk Enterprise and Universal Forwarder components are documented | Partial |
| Data Protection | Encrypted EBS volumes, encrypted CloudTrail storage and S3 public-access protection | Partial |
| Secure Configuration of Enterprise Assets and Software | Terraform configuration, IMDSv2 enforcement and restricted security groups | Partial |
| Account Management | IAM roles and Linux authentication monitoring | Partial |
| Access Control Management | Least-privilege IAM design, temporary role credentials and restricted administrative access | Partial |
| Continuous Vulnerability Management | Terraform Checkov scanning and controlled DVWA testing | Partial |
| Audit Log Management | CloudTrail, WAF, VPC Flow, Apache, authentication and syslog collection | Implemented for lab |
| Email and Web Browser Protections | Not implemented | Gap |
| Malware Defenses | Not implemented | Gap |
| Data Recovery | Recovery procedures documented; automated backup validation not implemented | Partial |
| Network Infrastructure Management | VPC, subnets, routing, ALB, security groups and Flow Logs | Implemented for lab |
| Network Monitoring and Defense | VPC Flow Logs, AWS WAF, Apache telemetry and Splunk analysis | Partial |
| Security Awareness and Skills Training | Detection documentation and investigation procedures | Documentation only |
| Service Provider Management | Not applicable to current lab scope | Not assessed |
| Application Software Security | DVWA attack validation, WAF inspection and web detection rules | Partial |
| Incident Response Management | Incident runbook, severity model, case study and closure criteria | Implemented as process |
| Penetration Testing | Controlled SQLi, XSS, traversal, reconnaissance and SSH simulations | Implemented in lab |

---

# CIS AWS Foundations Domain Mapping

The CIS AWS Foundations Benchmark evolves over time. Therefore, this document maps implemented capabilities to general benchmark domains rather than claiming exact benchmark-control compliance.

## Identity and Access Management

| Expected security practice | Project implementation | Gap or limitation |
|---|---|---|
| Avoid long-lived access keys where possible | EC2 monitoring uses IAM instance roles and temporary credentials | Manual verification still required |
| Apply least privilege | Splunk monitoring role is limited to required AWS log-reading capabilities | Formal permission-boundary testing not implemented |
| Protect privileged identities | Privilege-escalation activity is monitored through DET-004 | Organization-wide MFA enforcement not demonstrated |
| Monitor sensitive IAM changes | CloudTrail records IAM API activity in Splunk | Alert coverage should be expanded beyond current lab scenarios |
| Review unused credentials | Recommended in the incident runbook | No automated credential-age audit |

## Logging and Monitoring

| Expected security practice | Project implementation | Gap or limitation |
|---|---|---|
| Enable CloudTrail | Multi-Region CloudTrail is configured | Organization trail not implemented |
| Protect audit logs | CloudTrail logs use encrypted S3 storage and public-access blocking | Dedicated log-archive account not implemented |
| Monitor logging changes | DET-005 detects CloudTrail modification or disabling activity | Validated using non-persistent synthetic logic |
| Centralize log analysis | CloudTrail is ingested into Splunk Enterprise | Single-node SIEM has limited resilience |
| Monitor security-group changes | DET-006 identifies public exposure of sensitive services | Automated remediation is intentionally disabled |
| Monitor authentication | Linux SSH failures and successful logins are collected | No centralized enterprise identity provider |

## Networking

| Expected security practice | Project implementation | Gap or limitation |
|---|---|---|
| Restrict administrative access | Security groups use a trusted administrator CIDR | Requires correct deployment-time input |
| Record network flows | VPC Flow Logs are delivered to CloudWatch Logs | Continuous Splunk ingestion may be paused for cost and volume |
| Protect public applications | ALB is associated with AWS WAF | Managed rules may remain in count mode during testing |
| Separate workloads logically | Subnets and security groups define access boundaries | Lab currently uses public subnets |
| Detect unsafe exposure | DET-006 monitors security groups opened to the internet | No AWS Config managed-rule enforcement |

## Storage Protection

| Expected security practice | Project implementation | Gap or limitation |
|---|---|---|
| Block public S3 access | CloudTrail bucket uses S3 public-access blocking | Requires periodic validation |
| Encrypt stored audit data | CloudTrail bucket and EBS volumes are encrypted | Customer-managed KMS key rotation is not implemented |
| Restrict bucket access | Bucket policy limits CloudTrail delivery and monitoring access | No separate security-account ownership |
| Preserve logs | CloudTrail data is stored in S3 | Object Lock and immutable archive are not implemented |

---

# MITRE ATT&CK Detection Mapping

MITRE ATT&CK is used to describe the adversary behaviours addressed by the custom detections.

| Detection ID | Detection | Data source | ATT&CK technique |
|---|---|---|---|
| DET-001 | SSH Brute Force | Linux authentication | T1110 – Brute Force |
| DET-002 | SQL Injection Attempt | Apache access logs | T1190 – Exploit Public-Facing Application |
| DET-003 | Cross-Site Scripting Attempt | Apache access logs | T1190 – Exploit Public-Facing Application |
| DET-004 | Potential IAM Privilege Escalation | AWS CloudTrail | T1098 – Account Manipulation |
| DET-005 | CloudTrail Logging Modified or Disabled | AWS CloudTrail | T1562.008 – Disable or Modify Cloud Logs |
| DET-006 | Security Group Opened to the Internet | AWS CloudTrail | T1562.007 – Disable or Modify System Firewall |
| DET-007 | Repeated AWS WAF Rule Matches | AWS WAF | T1190 – Exploit Public-Facing Application |
| DET-008 | Directory Traversal Attempt | Apache access logs | T1190 – Exploit Public-Facing Application |
| DET-009 | Web Reconnaissance and Enumeration | Apache access logs | T1595 – Active Scanning |
| DET-010 | Successful SSH Login Following Multiple Failures | Linux authentication | T1110 – Brute Force |

> ATT&CK mappings describe the most relevant observed behaviour. They do not prove that an incident occurred or that every possible procedure associated with the technique is detected.

---

# Control Validation Methods

| Control | Validation method | Expected evidence |
|---|---|---|
| CloudTrail collection | Generate authorized AWS API activity | New `aws:cloudtrail` events in Splunk |
| Linux authentication monitoring | Perform controlled invalid SSH logins | `Invalid user` or failed authentication events |
| Web log collection | Send requests through the ALB | Events from both web-server hosts |
| SQLi detection | Send an encoded SQLi request to DVWA | DET-002 result |
| XSS detection | Send an encoded XSS request to DVWA | DET-003 result |
| WAF logging | Generate requests matching managed rules | WAF log containing rule-group matches |
| Network visibility | Review VPC Flow Log records | ACCEPT or REJECT flow events |
| Terraform security | Push Terraform changes | Successful format, validation and Checkov workflow |
| Detection quality | Modify or validate SPL files | Successful Python validation workflow |
| Incident response | Follow the documented investigation procedure | Completed incident case record |

---

# Security Gaps and Residual Risk

| Gap | Security impact | Recommended improvement | Priority |
|---|---|---|---|
| Single Splunk instance | Monitoring outage or data loss if the instance fails | Use distributed indexers, search heads and backups | High |
| DVWA is intentionally vulnerable | Internet exposure could allow real compromise | Restrict access to approved sources and shut down when unused | Critical |
| Public-subnet workloads | Larger external attack surface | Move application and SIEM workloads to private subnets | High |
| HTTP listener without TLS | Traffic is not encrypted in transit | Add ACM certificate and HTTPS listener | High |
| WAF count-mode rules | Malicious requests may be observed but not blocked | Move validated rules to block mode gradually | High |
| VPC Flow ingestion paused | Reduced real-time network visibility | Use filtered ingestion, S3 analytics or a larger SIEM design | Medium |
| No immutable log archive | A privileged actor could affect retained evidence | Use a dedicated log archive and S3 Object Lock | High |
| No automated asset inventory | Resource drift may go unnoticed | Add AWS Config and resource inventory reporting | Medium |
| No enterprise identity provider | Limited centralized access governance | Integrate IAM Identity Center and enforced MFA | Medium |
| No GuardDuty integration | Reduced managed threat-detection coverage | Add GuardDuty when cost and scope permit | Medium |
| No automated response | Containment depends on analyst availability | Add approval-based SOAR workflows | Medium |
| No formal backup testing | Recovery confidence is limited | Automate backups and conduct restoration tests | High |

---

# Production Readiness Recommendations

Before adapting this lab for production:

1. Move EC2 workloads into private subnets.
2. Use HTTPS with an ACM-managed certificate.
3. Remove DVWA and deploy a supported application.
4. Use AWS Organizations with centralized security and log-archive accounts.
5. Enforce MFA and federated administration.
6. Use customer-managed KMS keys where required.
7. Add AWS Config, Security Hub and GuardDuty.
8. Implement immutable and lifecycle-managed log retention.
9. Deploy a resilient, appropriately licensed SIEM architecture.
10. Baseline SPL thresholds against normal activity.
11. Introduce peer review and change control for detection rules.
12. Use analyst-approved SOAR playbooks for containment.
13. Test backup restoration and incident recovery.
14. Conduct periodic access, architecture and threat-model reviews.

---

# Control Status Definitions

| Status | Meaning |
|---|---|
| Implemented | Control is operating and evidence exists within the defined lab scope |
| Partially implemented | Some control outcomes are present, but production requirements are incomplete |
| Documentation only | Procedure exists but has not been technically automated |
| Gap | Control is not currently implemented |
| Not assessed | Control was outside the current project scope |

---

# References

- [NIST Cybersecurity Framework 2.0](https://www.nist.gov/cyberframework)
- [NIST CSF 2.0 Publication](https://www.nist.gov/publications/nist-cybersecurity-framework-csf-20)
- [CIS Critical Security Controls](https://www.cisecurity.org/controls)
- [CIS and Amazon Web Services](https://www.cisecurity.org/partner/amazon-web-services)
- [MITRE ATT&CK Enterprise](https://attack.mitre.org/)
- [MITRE ATT&CK Enterprise Techniques](https://attack.mitre.org/techniques/enterprise/)

---

## Related Project Documentation

- [Main Project README](../README.md)
- [Threat Model](threat-model.md)
- [Incident Response Runbook](incident-response-runbook.md)
- [Incident Case Study](incident-case-study.md)
- [Detection Validation Report](detection-validation.md)
- [Detection Rules](../detections/README.md)
- [Terraform Deployment Guide](../terraform/README.md)
