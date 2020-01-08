################################################################################
# AWS Provider
################################################################################
provider "aws" {
  access_key = "my-access-key"
  secret_key = "my-secret-key"
  region = "us-east-1"
}

################################################################################
# SSH Key
################################################################################
resource "aws_key_pair" "tf_deployer" {
  key_name   = "tf_deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFaNnnts6ASFl9hKSEjTibLDIKvsMqIte0QGnuBXLr4pmoZEZLVTjbn4YScdFYOrL07C5T2qQX6QQSJPR/1Cp/IpFh6TYdcV9nD6yKJnelfqV3SPcOwJgVMoa1GNKE5LAT2y+q22GbxH97TwlcxhVSI+pVWZg3DYvH03KHo9XKYv24ycjJTIXYezCOvSYgzmEEjwbNUliF5gCHSwGBM1Hh8Pu9xOEVho2OGAaWCSMRlae+k7pFttuwJT3SLEXzHRQhLDKQGJfW0l2+Y7YBlA005E5nDFsJLXt7Ae+6IlhZ29vPIScafWZs0ONXywif6xCc1CpKbj6Dgo98YdysSTlMY+zkCI8Rha6LM+fTQN4EUU7e+7pDGi0QhoiLOaqJbxRb3ggGOx65bWSh+EP0CXdxxy6BkzVfes+GCTenNWSpzvi2+A/M7g9+/b8LeQ7v0MKQIYQUGw7UfPgDImBY7EhX1Gq7AGAut8w4IYS+FV0sAs0xs5QZKoPokeseIPStoZhCyPt/KTZiPDtQ3/XoBReC3TS1HrPf/ZJRpqd6oY+njAbtdSB+lZZa5WD1/RLoDWQODDsYmuC5mCTZktpMO7QXGp9s80b0DPQjl0Y3mvkGfHt4gUjKeDvsE1Kl3T1xhIjpHThVpfQn5jMN6YL40xHinLb/T/mHFTDhvGtO+FEHFw== bryamada@gmail.com"
}

################################################################################
# VPC
################################################################################
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "TF-VPC-MAIN"
  }
}

# Subnets
resource "aws_subnet" "public_0" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "TF-SUBNET-PUBLIC-0"
  }
}
resource "aws_subnet" "private_0" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "TF-SUBNET-PRIVATE-0"
  }
}

# Gateways
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}
resource "aws_eip" "nat" {}
resource "aws_nat_gateway" "main-natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.private_0.id

  tags = {
    Name = "main-nat"
  }
}

# Route Tables
resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main_public_rt"
  }
}
resource "aws_route_table" "main_private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main-natgw.id
  }

  tags = {
    Name = "main_private_rt"
  }
}

# Route table associantions
resource "aws_route_table_association" "public_assoc_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.main_public_rt.id
}
resource "aws_route_table_association" "private_assoc_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.main_private_rt.id
}

################################################################################
# Security Groups
################################################################################
resource "aws_security_group" "tf_nw_challenge_allow_ssh" {
  name   = "tf_nw_challenge_allow_ssh"
  vpc_id = aws_vpc.main.id

  # TLS
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_nw_challenge_allow_ssh"
  }
}

resource "aws_security_group" "tf_nw_challenge_allow_web" {
  name   = "tf_nw_challenge_allow_web"
  vpc_id = aws_vpc.main.id

  # TLS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_nw_challenge_allow_web"
  }
}

resource "aws_security_group" "tf_nw_challenge_internal" {
  name   = "tf_nw_challenge_internal"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.100.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_nw_challenge_internal"
  }
}

################################################################################
# EC2 Instances
################################################################################
resource "aws_instance" "tf_nw_challenge" {
  ami                         = "ami-02eac2c0129f6376b" # centos 7
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  key_name                    = "tf_deployer"

  subnet_id = aws_subnet.public_0.id
  security_groups = [
    aws_security_group.tf_nw_challenge_allow_web.id,
    aws_security_group.tf_nw_challenge_internal.id,
    aws_security_group.tf_nw_challenge_allow_ssh.id
  ]

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 20
  }

  volume_tags = {
    Name = "tf_nw_challenge"
  }

  tags = {
    Name = "tf_nw_challenge"
  }
}
