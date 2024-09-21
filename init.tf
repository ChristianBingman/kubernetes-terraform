terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.15.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "metrics-server" {
   source = "./modules/metrics_server"
}

module "cert-manager" {
  source = "./modules/cert-manager"
  cloudflare_api_token = var.cert-manager_cloudflare_api_token
}

module "cnpg" {
  source = "./modules/cnpg"
}

module "prometheus-stack" {
  source = "./modules/prometheus-stack"
  admin_password = var.prometheus-stack_grafana_admin_password
  smtp_host = var.smtp_host
  smtp_user = var.smtp_user
  smtp_pass = var.smtp_pass
}

module "metallb" {
  source = "./modules/metallb"
}
