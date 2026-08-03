data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "sqlserver" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.sqlserver_instance_type
  subnet_id              = aws_subnet.a.id
  vpc_security_group_ids = [aws_security_group.source.id]
  key_name               = var.ec2_key_name
  root_block_device {
    volume_size = 80
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = aws_kms_key.data.arn
  }
  user_data                   = templatefile("${path.module}/user-data/sqlserver.sh.tftpl", { sqlserver_password = var.sqlserver_password })
  user_data_replace_on_change = true
  tags                        = { Name = "${local.name}-sqlserver-source" }
}
