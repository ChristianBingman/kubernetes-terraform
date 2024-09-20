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
      "--dns01-recursive-nameservers=${join(",", var.recursive_nameservers)}"
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
