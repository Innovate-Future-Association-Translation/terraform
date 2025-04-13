provider "aws" {
  region = var.region
}

locals {
  account_id = data.aws_caller_identity.current.account_id

  tags = {
    managedBy = "terraform"
  }
}

data "aws_caller_identity" "current" {}

################################################################################
# ECR Repository
################################################################################


module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = var.ecr_name

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  create_lifecycle_policy           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true

  tags = local.tags
}

data "aws_iam_policy_document" "registry" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions   = ["ecr:ReplicateImage"]
    resources = [module.ecr.repository_arn]
  }

  statement {
    sid = "dockerhub"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions = [
      "ecr:CreateRepository",
      "ecr:BatchImportUpstreamImage"
    ]
    resources = ["arn:aws:ecr-public::${local.account_id}:repository/dockerhub/*"]
  }
}

module "ecr_registry" {
  source = "terraform-aws-modules/ecr/aws"

  create_repository = false

  # Registry Policy
  create_registry_policy = true
  registry_policy        = data.aws_iam_policy_document.registry.json

  # Registry Pull Through Cache Rules
  registry_pull_through_cache_rules = {
    pub = {
      ecr_repository_prefix = "ecr-public"
      upstream_registry_url = "public.ecr.aws"
    }
    dockerhub = {
      ecr_repository_prefix = "dockerhub"
      upstream_registry_url = "registry-1.docker.io"
      credential_arn        = module.secrets_manager_dockerhub_credentials.secret_arn
    }
  }
}
resource "random_password" "pull_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

module "secrets_manager_dockerhub_credentials" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.0"

  # Secret names must contain 1-512 Unicode characters and be prefixed with ecr-pullthroughcache/
  name_prefix = "ecr-pullthroughcache/dockerhub-credentials"
  description = "Dockerhub credentials"

  recovery_window_in_days = 0
  secret_string = jsonencode({
    username    = var.ecr_pull_user
    accessToken = resource.random_password.pull_password.result
  })

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read = {
      sid = "AllowAccountRead"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.account_id}:root"]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  tags = local.tags
}