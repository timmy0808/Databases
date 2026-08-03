# AWS architecture

The lab uses SQL Server 2022 Developer Edition in a container on EC2 as the self-managed source and Amazon RDS for PostgreSQL as the target. AWS DMS performs the initial full load and then reads SQL Server transaction-log changes for CDC.

```mermaid
flowchart LR
  ADMIN["Migration engineer<br/>Terraform | AWS CLI | SSH"]
  SECRETS["Secrets Manager<br/>Database credentials"]
  KMS["AWS KMS<br/>Encryption key"]
  CW["CloudWatch<br/>Logs | metrics | alarms"]

  subgraph VPC["VPC | 10.42.0.0/16"]
    subgraph SOURCE_SG["Source security group"]
      EC2["EC2 jump host<br/>SQL Server 2022 container"]
    end
    subgraph DMS_SG["DMS security group"]
      DMS["AWS DMS<br/>Full load + CDC<br/>Row-level validation"]
    end
    subgraph TARGET_SG["PostgreSQL security group"]
      RDS[("RDS PostgreSQL 16<br/>Private and encrypted")]
    end

    EC2 -->|"TCP 1433<br/>Transaction-log CDC"| DMS
    DMS -->|"TLS over TCP 5432"| RDS
  end

  ADMIN -->|SSH 22| EC2
  ADMIN -->|"SSH tunnel<br/>localhost:5433"| RDS
  SECRETS -.-> EC2
  SECRETS -.-> RDS
  KMS -.-> EC2
  KMS -.-> DMS
  KMS -.-> RDS
  DMS --> CW
```

See [Migration architecture and evidence](../docs/migration-evidence.md) for screenshots from the deployed lab.

## Network flow

- Administrator → EC2: SSH 22 and optional SQL Server 1433 from a single CIDR.
- DMS security group → EC2 source security group: TCP 1433.
- DMS security group → RDS target security group: TCP 5432.
- EC2 source/jump security group → RDS target security group: TCP 5432.
- RDS and DMS are not publicly accessible.

## Security controls represented

- KMS encryption for EBS, RDS, DMS storage, and Secrets Manager.
- TLS required on the PostgreSQL DMS endpoint.
- RDS backups and PostgreSQL log export enabled.
- CloudWatch alarms for source and target CDC latency.
- Synthetic data classification tags.

The source endpoint uses a broad SQL Server account for lab simplicity. Production should replace it with the AWS-documented least-privilege model and formal credential rotation.
