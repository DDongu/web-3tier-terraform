data "terraform_remote_state" "shared" {
  backend = "local"

  config = {
    path = "../shared/terraform.tfstate"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_attachment" {
  vpc_id             = aws_vpc.dev_vpc.id
  subnet_ids         = [aws_subnet.pub_sub_1.id]
  transit_gateway_id = data.terraform_remote_state.shared.outputs.transit_gateway_id

  tags = {
    Name = "dev-vpc-attachment"
  }
}
