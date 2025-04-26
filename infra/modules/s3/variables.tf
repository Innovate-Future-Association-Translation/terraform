variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "bucket_name_prefix" {
  description = "Prefix for the frontend S3 bucket name"
  type        = string
  default     = "frontend-site"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Name = "FrontendHosting"
  }
}
