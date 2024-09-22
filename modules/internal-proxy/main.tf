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
      server {
        listen 443 ssl;
        server_name grafana.kubernetes-prod.christianbingman.com;
        ssl_certificate /etc/nginx/ssl/grafana.kubernetes-prod.christianbingman.com/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/grafana.kubernetes-prod.christianbingman.com/tls.key;

        location / {
          proxy_set_header Host $host;
          proxy_pass http://prometheus-stack-grafana.prometheus-stack;
        }

        # Proxy Grafana Live WebSocket connections.
        location /api/live/ {
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
          proxy_set_header Host $host;
          proxy_pass http://prometheus-stack-grafana.prometheus-stack;
        }
      }
      server {
        listen 80;
        server_name pushgateway.kubernetes-prod.christianbingman.com;

        location / {
          proxy_set_header Host $host;
          proxy_pass http://pushgateway-http.prometheus-stack;
        }
      }
      server {
        listen 80 default_server;
        server_name _;

        location /healthz {
          return 200;
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
    port {
      name = "https"
      port = 443
      protocol = "TCP"
      target_port = 443
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

resource "kubernetes_manifest" "grafana-https" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "grafana-https"
      "namespace" = "internal-proxy"
    }
    "spec" = {
      "secretName" = "grafana-https"
      "dnsNames" = [
        "grafana.kubernetes-prod.christianbingman.com"
      ]
      "issuerRef" = {
        "name" = "le-christianbingman-com"
        "kind" = "ClusterIssuer"
      }
    }
  }
}
