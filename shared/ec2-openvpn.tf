resource "aws_security_group" "openvpn_sg" {
  name        = "openvpn-sg"
  description = "Allow OpenVPN traffic"
  vpc_id      = aws_vpc.shared_vpc.id

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openvpn-sg"
  }
}

resource "aws_instance" "openvpn" {
  ami                         = "ami-0ba7b69b8b03f0bf1"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.openvpn_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "OpenVPN-Server"
  }
}