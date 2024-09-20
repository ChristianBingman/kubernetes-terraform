resource "helm_release" "cnpg" {
  name = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart = "cloudnative-pg"
  namespace = "cnpg-system"
  create_namespace = true

  set {
    name = "monitoring.podMonitorEnabled"
    value = true
  }

  set {
    name = "monitoring.grafanaDashboard.create"
    value = true
  }
}
