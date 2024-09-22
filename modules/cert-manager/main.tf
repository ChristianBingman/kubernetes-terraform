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

resource "kubernetes_manifest" "le-christianbingman-com" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "le-christianbingman-com"
    }
    "spec" = {
      "acme" = {
        "email" = "christianbingman@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "dns01" = {
              "cloudflare" = {
                "apiTokenSecretRef" = {
                  "key" = "api-token"
                  "name" = "cloudflare-api-token-secret"
                }
              }
            }
          },
        ]
      }
    }
  }
}

resource "kubernetes_secret" "cloudflare-api-token-secret" {
  metadata {
    name = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }
  data = {
    apiToken = var.cloudflare_api_token
  }
  type = "kubernetes.io/opaque"
}
