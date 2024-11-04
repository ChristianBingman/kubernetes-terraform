resource "kubernetes_namespace" "website" {
  metadata {
    name = var.namespace
    labels = {
      app = var.selector
    }
  }
}

resource "kubernetes_deployment" "website" {
  metadata {
    name = "root-site"
    namespace = var.namespace
    labels = {
      app = var.selector
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = var.selector
      }
    }
    template {
      metadata {
        labels = {
          app = var.selector
        }
      }
      spec {
        container {
          name = "nginx-container"
          image = "nginx:latest"
          port {
            container_port = 80
          }
          resources {
            limits = {
              memory = "256Mi"
            }
            requests = {
              memory = "128Mi"
              cpu = "100m"
            }
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds = 60
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds = 15
          }
          volume_mount {
            name = "nginx-conf"
            mount_path = "/etc/nginx/conf.d/rootsite.conf"
            sub_path = "rootsite.conf"
            read_only = true
          }
          volume_mount {
            name = "maintenance-page"
            mount_path = "/usr/share/nginx/html/rootsite/maintenance.html"
            sub_path = "maintenance.html"
            read_only = true
          }
        }
        volume {
          name = "nginx-conf"
          config_map {
            name = "nginx-conf-9"
            items {
              key = "rootsite.conf"
              path = "rootsite.conf"
            }
          }
        }
        volume {
          name = "maintenance-page"
          config_map {
            name = "nginx-conf-9"
            items {
              key = "maintenance.html"
              path = "maintenance.html"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "nginx-conf" {
  metadata {
    name = "nginx-conf-9"
    namespace = var.namespace
    labels = {
      app = var.selector
    }
  }
  data = {
    "rootsite.conf" = <<-EOF
      server {
        listen 80 default_server;
        server_name www.christianbingman.com christianbingman.com;

        error_page 503 /maintenance.html;
        location = /maintenance.html {
          root /usr/share/nginx/html/rootsite;
        }

        location / {
          return 503;
        }

        location /healthz {
          return 200;
        }

      }
    EOF
    "maintenance.html" = <<-EOF
      <html>
        <head>
          <title>Under maintenance</title>
        </head>
        <body>
          <h1>Site Under Maintenance</h1>
          <p>Site is currently under maintenance</p>
        </body>
      </html>
    EOF
  }
}

resource "kubernetes_service" "root-site-http" {
  metadata {
    name = "root-site-http"
    namespace = var.namespace
    labels = {
      app = var.selector
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
      app = var.selector
    }
    type = "ClusterIP"
  }
}
