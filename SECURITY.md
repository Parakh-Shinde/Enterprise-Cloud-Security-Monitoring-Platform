# Security Policy

## Project Scope

This repository documents an authorized cloud-security lab built for education, detection engineering, and defensive-security research.

The environment contains intentionally vulnerable applications and must not be deployed as a production service.

## Reporting a Security Issue

If you identify a security issue:

1. Do not disclose credentials, tokens, account IDs, private infrastructure details, or exploit information in a public issue.
2. Use GitHub Private Vulnerability Reporting or a Security Advisory when available.
3. Include the affected component, reproduction steps, impact, and recommended remediation.
4. Allow reasonable time for validation and remediation before public disclosure.

## Supported Version

Only the latest version of the `main` branch is maintained.

| Version | Supported |
|---|---|
| Latest `main` branch | Yes |
| Older commits and forks | No |

## Sensitive Information

This repository must never contain:

- AWS access keys or secret keys
- SSH private keys or `.pem` files
- Splunk passwords or authentication tokens
- API keys
- Webhook secrets
- Session cookies
- Terraform state containing sensitive values
- Unredacted AWS account or infrastructure identifiers

If a credential is committed accidentally, revoke or rotate it immediately. Deleting the file alone does not remove it from Git history.

## Authorized Testing Only

The SPL detections and attack simulations are intended only for systems owned by the tester or covered by explicit written authorization.

Do not use this project to scan, exploit, disrupt, or access third-party systems.

## Production Disclaimer

This is a lab implementation. Detection thresholds, IAM permissions, WAF actions, logging, retention, network controls, and incident-response procedures require formal review before production use.
