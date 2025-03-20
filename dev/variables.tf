# 입력 변수 작성

variable "app_port" {
  description = "Webapp's HTTP port"
  type = number
  default = 80
}

variable "server_port" {
  description = "Webserver's HTTP port"
  type = number
  default = 3000
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