## test changes
locals {
  aws_region       = "us-west-2"
  environment_name = "staging"
  tags = {
    ops_env              = "${local.environment_name}"
    ops_managed_by       = "terraform",
    ops_source_repo      = "kubernetes-ops",
    ops_source_repo_path = "terraform-environments/aws/${local.environment_name}/10-vpc",
    ops_owners           = "devops",
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.37.0"
    }
  }

  backend "remote" {
    organization = "spanda-eks"

    workspaces {
      name = "kubernetes-ops-staging-10-vpc"
    }
  }
}

provider "aws" {
  region = local.aws_region
}

#
# VPC
#
#
module "vpc" {
  source = "github.com/ManagedKube/kubernetes-ops//terraform-modules/aws/vpc?ref=v1.0.24"

  aws_region         = local.aws_region
  azs                = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
  vpc_cidr           = "10.0.0.0/16"
  secondary_cidrs    = ["103.1.0.0/16"]
  private_subnets    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24", "10.0.104.0/24"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  k8s_worker_subnets = ["103.1.0.0/24", "103.1.2.0/24", "103.1.3.0/24"]
  environment_name   = local.environment_name
  cluster_name       = local.environment_name
  tags               = local.tags
  enable_vpn_gateway = false
}
