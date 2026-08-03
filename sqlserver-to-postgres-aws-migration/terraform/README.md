# Terraform deployment

This stack creates the AWS resources used by the DMS migration lab. See the root `README.md` for the complete workflow.

## Cost warning

EC2, RDS, DMS, storage, backups, and CloudWatch can incur charges while provisioned. Destroy the lab after use:

```powershell
terraform destroy
```

## State security

Database passwords are sensitive Terraform variables but remain present in Terraform state because the AWS resources require them. Use an encrypted remote state backend with restricted IAM permissions for non-disposable environments.
