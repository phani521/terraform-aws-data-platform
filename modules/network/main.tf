variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "ppd-${var.env}-vpc"
    Environment = var.env
  }
}

# Public subnet for NAT
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 10)
  map_public_ip_on_launch = true

  tags = {
    Name        = "ppd-${var.env}-public-0"
    Environment = var.env
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "ppd-${var.env}-igw"
    Environment = var.env
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "ppd-${var.env}-public-rt"
    Environment = var.env
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# EIP for NAT (note: no 'vpc' argument)
resource "aws_eip" "nat" {
  tags = {
    Name        = "ppd-${var.env}-nat-eip"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "ppd-${var.env}-nat"
    Environment = var.env
  }
}

# Private subnets for EMR/EKS
resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "ppd-${var.env}-private-${count.index}"
    Environment = var.env
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "ppd-${var.env}-private-rt"
    Environment = var.env
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}
