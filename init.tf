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

resource "helm_release" "cert-manager" {
  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  namespace = "cert-manager"
  create_namespace = true
  version = "v1.15.0"

  set {
    name = "crds.enabled"
    value = true
  }

  set_list {
    name = "extraArgs"
    value = [
      "--dns01-recursive-nameservers-only",
      "--dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53"
    ]
  }

  set {
    name = "prometheus.enabled"
    value = true
  }

  set {
    name = "prometheus.servicemonitor.enabled"
    value = true
  }
}
