variable "aws_region" {
  type    = string
  default = "us-west-2"
}
variable "project_name" {
  type    = string
  default = "transplant-dms-lab"
}
variable "admin_cidr" {
  type        = string
  description = "Administrator public IPv4 CIDR, normally x.x.x.x/32"
}
variable "ec2_key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}
variable "sqlserver_password" {
  type      = string
  sensitive = true
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "sqlserver_instance_type" {
  type    = string
  default = "t3.large"
}
variable "dms_instance_class" {
  type    = string
  default = "dms.t3.medium"
}
variable "postgres_instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "postgres_engine_version" {
  type    = string
  default = "16"
}
variable "postgres_allocated_storage" {
  type    = number
  default = 50
}
variable "multi_az" {
  type    = bool
  default = false
}
