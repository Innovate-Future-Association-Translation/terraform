provider "aws" {
  region = "ap-southeast-2" # 根据你的需求修改
}

module "my_s3_bucket" {
  source        = "./modules/s3"
}
