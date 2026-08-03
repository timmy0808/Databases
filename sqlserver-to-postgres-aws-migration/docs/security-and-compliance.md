# Security and compliance considerations

The project contains only synthetic records, but models controls appropriate for sensitive clinical data:

- Private RDS and DMS networking.
- Security-group-to-security-group access instead of broad database CIDRs.
- Encryption at rest with KMS and TLS for PostgreSQL transport.
- Secrets stored in Secrets Manager, with a warning that Terraform state also requires protection.
- CloudWatch database and migration logging.
- Limited administrative ingress from one CIDR.
- Explicit data validation and migration evidence retention.

Production additions would include least-privilege DMS database users, AWS Config and CloudTrail controls, centralized log retention, GuardDuty, vulnerability management, formal BAA/account controls, key policies, credential rotation, data retention, and tested backup/restore procedures.
