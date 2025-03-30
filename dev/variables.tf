variable "shared_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

# 입력 변수 작성
variable "app_port" {
  description = "Webapp's HTTP port"
  type = number
  default = 3000
}

variable "server_port" {
  description = "Webserver's HTTP port"
  type = number
  default = 8080
}

variable "my_ip" {
  description = "My public IP"
  type = string
  default = "0.0.0.0/0"
}

variable "server_alb_security_group_name" {
  description = "The name of the server ALB's security group"
  type = string
  default = "webserver-alb-sg-todyN"
}

variable "server_alb_name" {
  description = "The name of the server ALB"
  type = string
  default = "webserver-alb-tobyN"
}

variable "app_alb_security_group_name" {
  description = "The name of the app ALB's security group"
  type = string
  default = "webapp-alb-sg-todyN"
}

variable "app_alb_name" {
  description = "The name of the app ALB"
  type = string
  default = "webapp-alb-tobyN"
}

# 프론트엔드 배포용 변수 추가

variable "docker_image_bucket_name" {
  description = "The name of the docker-image bucket(S3)"
  type = string
  default = "docker-image-storage-bucket"
}

variable "docker_webapp_codedeploy_name" {
  description = "The name of the webapp_codedeploy"
  type = string
  default = "DockerCodeDeployApp"
}

variable "docker_webapp_codedeploy_group_name" {
  description = "The name of the webapp_codedeploy Group"
  type = string
  default = "DockerDeploymentAppGroup"
}

# 백엔드 배포용 변수 추가
variable "docker_backend_codedeploy_name" {
  description = "The name of the backend CodeDeploy application"
  type        = string
  default     = "BackendCodeDeployApp"
}

variable "docker_backend_codedeploy_group_name" {
  description = "The name of the backend CodeDeploy deployment group"
  type        = string
  default     = "BackendDeploymentAppGroup"
}

# DocumentDB 관련(with. MongoDB)
variable "docdb_cluster_id" {
  description = "DocumentDB Cluster ID"
  default     = "my-docdb-cluster"
}

variable "docdb_instance_class" {
  description = "DocumentDB Instance Type"
  default     = "db.r5.large"
}

variable "docdb_instance_count" {
  description = "Number of DocumentDB instances"
  default     = 1
}

variable "docdb_username" {
  description = "DocumentDB admin username"
  default     = "docdb_admin"
}

variable "docdb_password" {
  description = "DocumentDB admin password"
  default     = "SecurePassword123" # 변경 필요
}

variable "docdb_subnet_ids" {
  description = "List of subnet IDs for DocumentDB"
  default     = []
}

variable "docdb_security_group_name" {
  description = "DocumentDB Security Group Name"
  default     = "docdb-security-group"
}
