variable "name_prefix" {
  default = "demo-antoneo"
}

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "az_count" {
  default = "2"
}

variable "healthcheck_path" {
  default = "/"
}

variable "fargate_cpu" {
  default = "1024"
}

variable "fargate_memory" {
  default = "2048"
}

variable "ecs_task_execution_role_name" {
  default = "ecsTaskExecutionRole"
}

variable "ecs_autoscale_role_name" {
  default = "aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
}

variable "min_capacity" {
  default = "2"
}

variable "max_capacity" {
  default = "5"
}

variable "container_port" {
  default = "8000"
}

variable "host_port" {
  default = "80"
}

variable "alb_protocol" {
  default = "HTTP"
}

variable "balanced_container_name" {
  default = "antoneo-api"
}

variable "app_image" {
  default = "k8s.gcr.io/hpa-example:latest"
}

variable "infra_vpc_id" {
  description = "infra vpc id"
}

variable "app_vpc_id" {
  description = "application vpc id"
}

variable "vpc_private_subnets" {
  description = "infra vpc private subnets"
}


variable "alb_https_listener" {
  description = "alb https listener arn"
}


variable "api_domain_name" {
  description = "the domain that ecs gonna use"
}