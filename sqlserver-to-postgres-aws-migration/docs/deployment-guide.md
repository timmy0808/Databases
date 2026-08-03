# Deployment guide

1. Create or identify an EC2 SSH key pair.
2. Set `admin_cidr` to the administrator's current public IP with `/32`.
3. Apply Terraform.
4. Confirm the SQL Server Docker container is healthy on EC2.
5. Apply the source schema and CDC preparation scripts.
6. Connect to private RDS through an SSH tunnel and apply the target schema.
7. Test both DMS endpoints.
8. Run the DMS premigration assessment.
9. Start full load plus CDC.
10. Monitor table statistics, CloudWatch logs, and latency metrics.
11. Apply post-full-load constraints and run independent validation.
12. Rehearse and execute cutover.
13. Destroy the lab when finished.
