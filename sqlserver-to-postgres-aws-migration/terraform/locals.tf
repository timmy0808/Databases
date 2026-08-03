locals {
  name = lower(var.project_name)
  tags = {
    Project     = var.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
    DataClass   = "Synthetic"
  }
}
