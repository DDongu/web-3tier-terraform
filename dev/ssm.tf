# DB URI
resource "aws_ssm_parameter" "documentdb_uri" {
  name  = "/my-app/documentdb-uri"
  type  = "SecureString"
  value = aws_docdb_cluster.docdb.endpoint
}

# 백엔드 ELB 주소(URL)
resource "aws_ssm_parameter" "backend_elb_url" {
  name  = "/my-app/backend-elb-url"
  type  = "String"
  value = aws_lb.webserver_alb.dns_name
}