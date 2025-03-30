# VPC 생성
resource "aws_vpc" "shared_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "OpenVPN-VPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.shared_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "Public-Subnet"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "vpn_igw_shared" {
  vpc_id = aws_vpc.shared_vpc.id

  tags = {
    Name = "VPN-IGW"
  }
}

# 라우트 테이블
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.shared_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_igw_shared.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

## Dev VPC Route Table
resource "aws_route" "shared_to_dev" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = var.vpc_dev_cidr # "10.10.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}


# 라우트 테이블 연결
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
