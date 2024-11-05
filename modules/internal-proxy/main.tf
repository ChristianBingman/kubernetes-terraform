resource "kubernetes_namespace" "internal-proxy" {
  metadata {
    name = "internal-proxy"
    labels = {
      app = "proxy"
    }
  }
}

resource "kubernetes_deployment" "internal-proxy" {
  metadata {
    labels = {
      app = "proxy"
    }
    name = "internal-proxy"
    namespace = "internal-proxy"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "proxy"
        }
      }
      spec {
        container {
          image = "nginx:latest"
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds = 10
          }
          name = "nginx-container"
          port {
            container_port = 80
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds = 5
          }
          resources {
            limits = {
              memory = "256Mi"
            }
            requests = {
              cpu = "100m"
              memory = "128Mi"
            }
          }
          volume_mount {
            mount_path = "/etc/nginx/conf.d/proxies.conf"
            name = "nginx-conf"
            read_only = true
            sub_path = "proxies.conf"
          }
          volume_mount {
            mount_path = "/etc/nginx/ssl/grafana.kubernetes-prod.christianbingman.com"
            name = "grafana-https-vol"
            read_only = true
          }
        }
        volume {
          config_map {
            items {
                key = "proxies.conf"
                path = "proxies.conf"
              }
            name = "proxy-conf-11"
          }
          name = "nginx-conf"
        }
        volume {
          name = "grafana-https-vol"
          secret {
            secret_name = "grafana-https"
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "proxy-conf" {
  metadata {
    name = "proxy-conf-11"
    namespace = "internal-proxy"
    labels = {
      app = "proxy"
    }
  }

  data = {
    "proxies.conf" = <<-EOT
      server_names_hash_bucket_size  128;
      map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
      }
      server {
        listen 80;
        server_name www.christianbingman.com christianbingman.com;

        location / {
          proxy_pass http://root-site-http.root-site/;
        }
      }
    EOT
  }
}

resource "kubernetes_service" "internal-proxy-http" {
  metadata {
    name = "internal-proxy-http"
    namespace = "internal-proxy"
    annotations= {
      "metallb.universe.tf/loadBalancerIPs" = "10.2.0.26"
      "metallb.universe.tf/ip-allocated-from-pool" = "default-pool"
    }
    labels = {
      app = "proxy"
    }
  }

  spec {
    port {
      name = "http"
      port = 80
      protocol = "TCP"
      target_port = 80
    }
    selector = {
      app = "proxy"
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "internal-proxy" {
  metadata {
    name = "internal-proxy"
    namespace = "internal-proxy"
  }

  spec {
    min_replicas = 2
    max_replicas = 6
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          average_utilization = 60
          type = "Utilization"
        }
      }
    }
    scale_target_ref {
      name = "internal-proxy"
      kind = "Deployment"
    }
  }
}
