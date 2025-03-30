variable "app_environment" {
  description = "Number of DocumentDB instances"
  type = string
  default = "shared"
}

variable "region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = "aws-practice-key"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_dev_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.0.0/25"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "ap-northeast-2a"
}

variable "project" {  
  type        = string
  default     = "personal-project"
}

variable "environment" {  
  type        = string
  default     = "personal-project"
}
