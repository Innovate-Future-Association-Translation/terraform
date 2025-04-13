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