resource "aws_ec2_transit_gateway_vpc_attachment" "shared_attachment" {
  vpc_id             = aws_vpc.shared_vpc.id
  subnet_ids         = [aws_subnet.public_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "shared-vpc-attachment"
  }
}
