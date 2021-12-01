locals {
  aws_region       = "us-west-2"
  environment_name = "staging"
  tags = {
    ops_env              = "${local.environment_name}"
    ops_managed_by       = "terraform",
    ops_source_repo      = "kubernetes-ops",
    ops_source_repo_path = "terraform-environments/aws/${local.environment_name}/helm/external-dns",
    ops_owners           = "devops",
  }
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.37.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "remote" {
    organization = "spanda-eks"

    workspaces {
      name = "kubernetes-ops-staging-helm-external-dns"
    }
  }
}

provider "aws" {
  region = local.aws_region
}

data "aws_eks_cluster" "eks" {
  name = local.environment_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", "${local.environment_name}"]
      command     = "aws"
    }
  }
}

data "aws_eks_cluster_auth" "main" {
  name = local.environment_name
}
//data "terraform_remote_state" "eks" {
//  backend = "remote"
//  config = {
//    organization = "managedkube"
//    workspaces = {
//      name = "kubernetes-ops-dev-20-eks"
//    }
//  }
//}

//data "terraform_remote_state" "route53_hosted_zone" {
//  backend = "remote"
//  config = {
//    organization = "managedkube"
//    workspaces = {
//      name = "kubernetes-ops-dev-5-route53-hostedzone"
//    }
//  }
//}

#
# EKS authentication
# # https://registry.terraform.io/providers/hashicorp/helm/latest/docs#exec-plugins
//provider "helm" {
//  kubernetes {
//    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
//    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
//    exec {
//      api_version = "client.authentication.k8s.io/v1alpha1"
//      args        = ["eks", "get-token", "--cluster-name", "${local.environment_name}"]
//      command     = "aws"
//    }
//  }
//}

#
# Helm - cluster-autoscaler
#
module "external-dns" {
  source = "github.com/ManagedKube/kubernetes-ops//terraform-modules/aws/helm/external-dns?ref=v1.0.28"

  aws_region                  = local.aws_region
  cluster_name                = local.environment_name
  eks_cluster_id              = data.aws_eks_cluster.eks.id
  eks_cluster_oidc_issuer_url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  route53_hosted_zones        = data.aws_route53_zone.selected.zone_id
  helm_values_2               = file("${path.module}/values.yaml")

  depends_on = [
    data.aws_eks_cluster.eks
  ]
}









data "aws_route53_zone" "selected" {
  name         = "pandademo.online."
  private_zone = false
}