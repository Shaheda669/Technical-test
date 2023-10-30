provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.application_name}"
  }
}

resource "aws_subnet" "public_subnet" {
  count = 2
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = element(var.public_subnet_cidr, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = element(var.private_subnet_cidr, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_security_group" "allow_redis" {
  vpc_id = aws_vpc.my_vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private_subnet[*].cidr_block
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${var.application_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-${var.application_name}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "ec2_instance" {
  count = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = element(aws_subnet.public_subnet[*].id, count.index)
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "ec2-instance-${count.index}"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = element(aws_subnet.public_subnet[*].id, 0)
}

resource "aws_eip" "my_eip" {
  instance = aws_instance.ec2_instance[0].id
}

resource "aws_elasticache_subnet_group" "my_subnet_group" {
  name       = "elasticache-subnet-group-${var.application_name}"
  description = "ElastiCache Subnet Group for ${var.application_name}"
  subnet_ids = aws_subnet.private_subnet[*].id
}

resource "aws_elasticache_cluster" "my_redis" {
  cluster_id           = "${var.application_name}-redis-cluster"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.my_subnet_group.name
  parameter_group_name = "default.redis6.x"
  security_group_ids   = [aws_security_group.allow_redis.id]
  port                 = 6379
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "${var.application_name}-s3"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.kms_key_id
      }
    }
  }
}

resource "aws_eip" "my_eip2" {
  instance = aws_instance.ec2_instance[1].id
}
