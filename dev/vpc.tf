provider "aws" {
    region = "ap-northeast-2"
    default_tags {
      tags = {
        Name = "toby-project"
        Subject = "personal-project"
      }
    }
}

# VPC CIDR 블록 변수
variable "vpc_dev_cidr" {
  description = "VPC dev CIDR block"
  default = "10.10.0.0/16"
}

# VPC 생성
resource "aws_vpc" "dev_vpc" {
  cidr_block = var.vpc_dev_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "toby-vpc"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  
  tags = {
    Name = "toby-igw"
  }
}

# 서브넷 생성
## Public 서브넷
resource "aws_subnet" "pub_sub_1" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2"
  }
}

## Private-NAT 서브넷 (NAT Gateway 전용)
resource "aws_subnet" "prv_nat_sub_1" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "Private-NAT-Subnet-1"
  }
}

resource "aws_subnet" "prv_nat_sub_2" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "Private-NAT-Subnet-2"
  }
}

## Private 서브넷
resource "aws_subnet" "prv_sub_1" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.10.4.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "Private-Subnet-1"
  }
}

resource "aws_subnet" "prv_sub_2" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.10.5.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "Private-Subnet-2"
  }
}

# Route Table 생성
## Public Route Table (인터넷 라우팅)
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

## Private Route Table (인터넷 접근 없음)
resource "aws_route_table" "prv_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "Private-Route-Table"
  }
}

## Shared VPC Route Table
resource "aws_route" "dev_to_shared" {
  route_table_id         = aws_route_table.prv_rt.id
  destination_cidr_block = var.shared_vpc_cidr # 예: "10.20.0.0/16"
  transit_gateway_id = data.terraform_remote_state.shared.outputs.transit_gateway_id
}


## Private-NAT Route Table (NAT Gateway 사용)
resource "aws_route_table" "prv_nat_rt1" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "Private-NAT-Route-Table-1"
  }
}

resource "aws_route_table" "prv_nat_rt2" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "Private-NAT-Route-Table-2"
  }
}

# Route Table과 Subnet을 연결
## Public 서브넷 연결
resource "aws_route_table_association" "pub_rt_asso_1" {
    subnet_id = aws_subnet.pub_sub_1.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt_asso_2" {
    subnet_id = aws_subnet.pub_sub_2.id
    route_table_id = aws_route_table.pub_rt.id
}

## Private 서브넷 연결
resource "aws_route_table_association" "prv_rt_asso_1" {
    subnet_id = aws_subnet.prv_sub_1.id
    route_table_id = aws_route_table.prv_rt.id
}

resource "aws_route_table_association" "prv_rt_asso_2" {
    subnet_id = aws_subnet.prv_sub_2.id
    route_table_id = aws_route_table.prv_rt.id
}

## Private-NAT 서브넷 연결
resource "aws_route_table_association" "prv_nat_rt1_asso" {
    subnet_id = aws_subnet.prv_nat_sub_1.id
    route_table_id = aws_route_table.prv_nat_rt1.id
}

resource "aws_route_table_association" "prv_nat_rt2_asso" {
    subnet_id = aws_subnet.prv_nat_sub_2.id
    route_table_id = aws_route_table.prv_nat_rt2.id
}

# EIP 생성 (NAT G/W 사용)
resource "aws_eip" "nat_eip1" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP-1"
  }
}

resource "aws_eip" "nat_eip2" {
  domain = "vpc"
  
  tags = {
    Name = "NAT-EIP-2"
  }
}

# NAT G/W 생성
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id = aws_subnet.pub_sub_1.id
  depends_on = [ aws_internet_gateway.dev_igw ]

  tags = {
    Name = "NAT-Gateway-1"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id = aws_subnet.pub_sub_2.id
  depends_on = [ aws_internet_gateway.dev_igw ]

  tags = {
    Name = "NAT-Gateway-2"
  }
}
