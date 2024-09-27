resource "kubernetes_deployment" "pushgateway" {
  metadata {
    name = "pushgateway"
    namespace = "prometheus-stack"
    labels = {
      app = "pushgateway"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels ={
        app = "pushgateway"
      }
    }
    template {
      metadata {
        labels = {
          app = "pushgateway"
        }
      }
      spec {
        container {
          name = "pushgateway-container"
          image = "prom/pushgateway:latest"
          port {
            container_port = 9091
          }
          liveness_probe {
            http_get {
              path = "/metrics"
              port = 9091
            }
            initial_delay_seconds = 15
            period_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/metrics"
              port = 9091
            }
            initial_delay_seconds = 5
            period_seconds = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pushgateway-http" {
  metadata {
    name = "pushgateway-http"
    namespace = "prometheus-stack"
    labels = {
      app = "pushgateway"
    }
  }
  spec {
    port {
      name = "http"
      protocol = "TCP"
      port = 80
      target_port = 9091
    }
    selector = {
      app = "pushgateway"
    }
    type = "ClusterIP"
  }
}
