provider "aws" {
    region = "ap-northeast-2"
    default_tags {
      tags = {
        Name = "toby-project"
        Subject = "personal-project"
      }
    }
}

# vpc 관련 변수 생성(cidr 블럭 변수)
variable "vpc_dev_cidr" {
  description = "VPC dev CIDR block"
  default = "10.0.0.0/23"
}

# vpc 생성
resource "aws_vpc" "dev_vpc" {
  cidr_block = var.vpc_dev_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = "10.1.0.0/23"
}

# Internet GateWay 생성
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
}

# 서브넷 생성
resource "aws_subnet" "pub_sub_1" {
  vpc_id = aws_vpc.dev_vpc.id # 사용할 VPC
  cidr_block = cidrsubnet(aws_vpc.dev_vpc.cidr_block, 2, 0) # cidr 블록 설정
  availability_zone = "ap-northeast-2a" # 사용할 가용영역
  map_public_ip_on_launch = true # 자동 퍼블릭 할당
}

resource "aws_subnet" "prv_nat_sub_1" {
  vpc_id = aws_vpc.dev_vpc.id 
  cidr_block = cidrsubnet(aws_vpc.dev_vpc.cidr_block, 2, 1) 
  availability_zone = "ap-northeast-2a" 
}

resource "aws_subnet" "prv_sub_1" {
  vpc_id = aws_vpc.dev_vpc.id 
  cidr_block = cidrsubnet(aws_vpc.dev_vpc.cidr_block, 2, 2) 
  availability_zone = "ap-northeast-2a" 
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 2, 0)
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "prv_nat_sub_2" {
    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 2, 1)
    availability_zone = "ap-northeast-2b"
}

resource "aws_subnet" "prv_sub_2" {
    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 2, 2)
    availability_zone = "ap-northeast-2b"
}

# Route Table 생성
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
}

resource "aws_route_table" "prv_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  # 완전한 private 서브넷은 라우팅이 없어야 된다고 함
}

resource "aws_route_table" "prv_nat_rt1" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }
}

resource "aws_route_table" "prv_nat_rt2" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }
}

# Route Table과 Subnet을 연결
## public
resource "aws_route_table_association" "pub_rt_asso" {
    subnet_id = aws_subnet.pub_sub_1.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt_asso2" {
    subnet_id = aws_subnet.pub_sub_2.id
    route_table_id = aws_route_table.pub_rt.id
}

## private
resource "aws_route_table_association" "prv_rt_asso" {
    subnet_id = aws_subnet.prv_sub_1.id
    route_table_id = aws_route_table.prv_rt.id
}

resource "aws_route_table_association" "prv_rt_asso2" {
    subnet_id = aws_subnet.prv_sub_2.id
    route_table_id = aws_route_table.prv_rt.id
}

## private-nat
resource "aws_route_table_association" "prv_nat_rt1_asso" {
    subnet_id = aws_subnet.prv_nat_sub_1.id
    route_table_id = aws_route_table.prv_nat_rt1.id
}

resource "aws_route_table_association" "prv_nat_rt2_asso" {
    subnet_id = aws_subnet.prv_nat_sub_2.id
    route_table_id = aws_route_table.prv_nat_rt2.id
}

# EIP 생성(NAT G/W에서 사용)
resource "aws_eip" "nat_eip1" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip2" {
  domain = "vpc"
}

# NAT G/W 생성
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id = aws_subnet.pub_sub_1.id
  depends_on = [ aws_internet_gateway.dev_igw ] # 명시적 의존성 선언(소스의 생성 순서를 지정 가능)
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id = aws_subnet.pub_sub_2.id
  depends_on = [ aws_internet_gateway.dev_igw ]
}