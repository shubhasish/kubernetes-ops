locals {
  aws_region       = "us-west-2"
  environment_name = "staging"
  namespace        = "ingress-nginx"
  tags = {
    ops_env              = "${local.environment_name}"
    ops_managed_by       = "terraform",
    ops_source_repo      = "kubernetes-ops",
    ops_source_repo_path = "terraform-environments/aws/${local.environment_name}/helm/ingress-nginx-external",
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "remote" {
    organization = "spanda-eks"

    workspaces {
      name = "kubernetes-ops-staging-helm-ingress-nginx"
    }
  }
}

provider "aws" {
  region = local.aws_region
}

//data "terraform_remote_state" "eks" {
//  backend = "remote"
//  config = {
//    organization = "spanda-eks"
//    workspaces = {
//      name = "kubernetes-ops-dev-20-eks"
//    }
//  }
//}

//data "terraform_remote_state" "route53_hosted_zone" {
//  backend = "remote"
//  config = {
//    organization = "gem-engineering"
//    workspaces = {
//      name = "kubernetes-ops-stage-5-route53-hostedzone"
//    }
//  }
//}

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

provider "kubectl" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

# Helm values file templating
data "template_file" "helm_values" {
  template = file("${path.module}/helm_values.tpl.yaml")

  # Parameters you want to pass into the helm_values.yaml.tpl file to be templated
  vars = {}
}

module "ingress-nginx-external" {
  source = "github.com/ManagedKube/kubernetes-ops//terraform-modules/aws/helm/helm_generic?ref=v1.0.9"

  # this is the helm repo add URL
  repository = "https://kubernetes.github.io/ingress-nginx"
  # This is the helm repo add name
  official_chart_name = "ingress-nginx"
  # This is what you want to name the chart when deploying
  user_chart_name = "ingress-nginx-external"
  # The helm chart version you want to use
  helm_version = "3.30.0"
  # The namespace you want to install the chart into - it will create the namespace if it doesnt exist
  namespace = local.namespace
  # The helm chart values file
  helm_values = data.template_file.helm_values.rendered

}

data "template_file" "helm_values_new" {
  template = file("${path.module}/helm_values_second.tpl.yaml")

  # Parameters you want to pass into the helm_values.yaml.tpl file to be templated
  vars = {}
}

module "ingress-nginx-external-new" {
  source = "github.com/ManagedKube/kubernetes-ops//terraform-modules/aws/helm/helm_generic?ref=v1.0.9"

  # this is the helm repo add URL
  repository = "https://kubernetes.github.io/ingress-nginx"
  # This is the helm repo add name
  official_chart_name = "ingress-nginx"
  # This is what you want to name the chart when deploying
  user_chart_name = "ingress-nginx-external-new"
  # The helm chart version you want to use
  helm_version = "3.30.0"
  # The namespace you want to install the chart into - it will create the namespace if it doesnt exist
  namespace = local.namespace
  # The helm chart values file
  helm_values = data.template_file.helm_values_new.rendered

}
//# file templating
//data "template_file" "certificate" {
//  template = file("${path.module}/certificate.tpl.yaml")
//
//  vars = {
//    baseDomainName = data.terraform_remote_state.route53_hosted_zone.outputs.domain_name
//    namespace      = local.namespace
//  }
//}
//
//resource "kubectl_manifest" "certificate" {
//  yaml_body = data.template_file.certificate.rendered
//}
