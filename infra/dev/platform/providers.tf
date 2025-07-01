terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      # Started to fail randomly for 6.0
      version = "~> 6.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


#  Import outputs from bootstrap layer to use on configs
data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = "andac-tfstate-dev"
    key    = "dev/bootstrap.tfstate"
    region = "eu-central-1"
  }
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.bootstrap.outputs.cluster_name
}

provider "kubernetes" {
  host = data.terraform_remote_state.bootstrap.outputs.endpoint
  cluster_ca_certificate = base64decode(
    data.terraform_remote_state.bootstrap.outputs.cluster_ca
  )
  token = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host = data.terraform_remote_state.bootstrap.outputs.endpoint
    cluster_ca_certificate = base64decode(
      data.terraform_remote_state.bootstrap.outputs.cluster_ca
    )
    token = data.aws_eks_cluster_auth.this.token
  }
}
