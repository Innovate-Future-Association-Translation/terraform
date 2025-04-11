provider "aws" {
  region = var.region
}

locals {
  # account_id = data.aws_caller_identity.current.account_id

  tags = {
    managedBy = "terraform"
  }

}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "641593750485-terraform-states"
    key    = "shared/alb.tfstate"
    region = var.region
  }
}

module "prodvpc" {
  source = "../modules/network"

  name = "prod-vpc"

  tags = {
    env = "prod"
  }

  cidr            = var.vpc_cidr
  private_subnets = var.private_cidrs
  public_subnets  = var.public_cidrs

}


module "ecs" {
  source              = "..//modules/ecs"
  app_vpc_id          = module.prodvpc.vpc_id
  vpc_private_subnets = module.prodvpc.private_subnets
  name_prefix         = var.ecs_name_prefix
  infra_vpc_id        = data.terraform_remote_state.infra.outputs.vpc_id
  aws_region          = var.region
  alb_https_listener  = data.terraform_remote_state.infra.outputs.alb_listener.https.arn
  app_image           = "crccheck/hello-world:latest"
  api_domain_name     = var.api_domain_name
}

####################
# Frontend
####################
module "prod-frontend" {
  source = "../modules/frontend"

  domain_name = var.domain_name
  sub_domain  = var.sub_domain
  bucket_name = var.bucket_name
  region      = var.region
}


resource "aws_route53_record" "api_record" {
  zone_id = data.terraform_remote_state.infra.outputs.route53_zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.infra.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.infra.outputs.alb_zone_id
    evaluate_target_health = true
  }

}


####################
# Netowrk Peering
####################
resource "aws_vpc_peering_connection" "foo" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = data.terraform_remote_state.infra.outputs.vpc_id
  vpc_id        = module.prodvpc.vpc_id
  auto_accept   = true

  tags = {
    Name = "VPC Peering between infra and prod"
  }
}


# route table for alb
resource "aws_route" "alb_to_ecs" {
  for_each                  = toset(module.prodvpc.private_subnets_rts)
  route_table_id            = each.value
  destination_cidr_block    = data.terraform_remote_state.infra.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.foo.id

}

# route from ecs to alb
resource "aws_route" "ecs_to_alb" {
  for_each                  = toset(data.terraform_remote_state.infra.outputs.public_subnets_rt)
  route_table_id            = each.value
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
}

# alb security group
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ecs" {
  security_group_id = data.terraform_remote_state.infra.outputs.alb_egress_sg
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags              = local.tags
}


################
# s3 bucket access
################
resource "aws_iam_user" "jenkins_user" {
  name = "jenkins-user-prod"
}

resource "aws_iam_access_key" "jenkins_access_key" {
  user = aws_iam_user.jenkins_user.name
}

# Optional: Attach a policy to this user
resource "aws_iam_user_policy" "jenkins_user_policy" {
  name = "jenkins-s3-policy-prod"
  user = aws_iam_user.jenkins_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListAllMyBuckets"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:s3:::*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          "${module.prod-frontend.bucket_arn}",
          "${module.prod-frontend.bucket_arn}/*"
        ]
      }
    ]
  })
}