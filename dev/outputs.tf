# DocumentDB 관련 출력(with. MongoDB)
output "documentdb_endpoint" {
  description = "DocumentDB Cluster Endpoint"
  value       = aws_docdb_cluster.docdb.endpoint
}

output "documentdb_sg_id" {
  description = "DocumentDB Security Group ID"
  value       = aws_security_group.docdb_sg.id
}
