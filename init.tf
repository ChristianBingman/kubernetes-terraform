terraform {
required_providers {
helm = {
source = "hashicorp/helm"
version = "2.15.0"
}
}
}

provider "helm" {
kubernetes {
config_path = "~/.kube/config"
}
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "metrics-server"
  create_namespace = true

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}
