resource "aws_ec2_transit_gateway" "main" {
  description = "TGW connecting dev and shared VPC"
  amazon_side_asn = 64512

  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "toby-tgw"
  }
}
