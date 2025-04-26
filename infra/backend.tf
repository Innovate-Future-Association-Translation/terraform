terraform {
  backend "s3" {
    bucket         = "ben-ifa-backend-state"  
    key            = "frontend/terraform.tfstate" # 👈 存在 S3 的路径
    region         = "ap-southeast-2"
    encrypt        = true
  }
}