# ✅ DocumentDB 보안 그룹 설정
resource "aws_security_group" "docdb_sg" {
  name   = var.docdb_security_group_name
  vpc_id = aws_vpc.dev_vpc.id

  # 백엔드(EC2)에서 MongoDB 연결 허용 (27017 포트)
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.docdb_security_group_name
  }
}

# ✅ DocumentDB 서브넷 그룹 생성
resource "aws_docdb_subnet_group" "docdb_subnet_group" {
  name       = "docdb-subnet-group"
  subnet_ids = var.docdb_subnet_ids

  tags = {
    Name = "docdb-subnet-group"
  }
}

# ✅ DocumentDB 클러스터 생성
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = var.docdb_cluster_id
  engine                 = "docdb"
  master_username        = var.docdb_username
  master_password        = var.docdb_password
  backup_retention_period = 7  # 백업 보관 일수
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot    = false  # 삭제 시 최종 백업 수행
  deletion_protection    = true   # 실수로 삭제 방지
  vpc_security_group_ids = [aws_security_group.docdb_sg.id]
  db_subnet_group_name   = aws_docdb_subnet_group.docdb_subnet_group.name
}

# ✅ DocumentDB 인스턴스 추가
resource "aws_docdb_cluster_instance" "docdb_instances" {
  count              = var.docdb_instance_count
  identifier        = "${var.docdb_cluster_id}-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = var.docdb_instance_class
}
