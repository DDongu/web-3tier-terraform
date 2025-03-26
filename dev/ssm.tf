# DocumentDB 접속 정보 (MongoDB URI 형식으로 저장)
resource "aws_ssm_parameter" "documentdb_uri" {
  name  = "/my-app/documentdb-uri"
  type  = "SecureString"
  value = "mongodb://${var.docdb_username}:${var.docdb_password}@${aws_docdb_cluster.docdb.endpoint}:27017/coronatracker?tls=true&tlsCAFile=/rds-cert/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
}

# 백엔드 ELB 주소(URL)
resource "aws_ssm_parameter" "backend_elb_url" {
  name  = "/my-app/backend-elb-url"
  type  = "String"
  value = "http://${aws_lb.webserver_alb.dns_name}:${var.server_port}"
}

# 프론트엔드 ELB 주소(URL)
resource "aws_ssm_parameter" "frontend_elb_url" {
  name  = "/my-app/frontend-elb-url"
  type  = "String"
  value = "http://${aws_lb.webapp_alb.dns_name}:${var.app_port}"

  tags = {
    Name        = "CORS Allowed Origin"
    Environment = "dev"
  }
}
