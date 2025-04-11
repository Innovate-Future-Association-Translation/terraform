variable "ecr_name" {
  description = "The name of created ecr"
  type        = string
  default     = "ecr-antonio-demo"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "ecr_pull_user" {
  description = "The username used to pull images from ecr"
  type        = string
  default     = "antoneo"
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.1.0.0/24"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "bucket_name" {
  type    = string
  default = "my-bucket"
}

variable "domain_name" {
  type    = string
  default = "exmaple.xyz"
}

variable "sub_domain" {
  type    = string
  default = "static"
}

variable "ecs_name_prefix" {
  type    = string
  default = "antoneo"
}

variable "api_domain_name" {
  type    = string
  default = "api"
}