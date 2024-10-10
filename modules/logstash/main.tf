resource "kubernetes_namespace" "logstash" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "logstash" {
  manifest = {
    "apiVersion" = "logstash.k8s.elastic.co/v1alpha1"
    "kind" = "Logstash"
    "metadata" = {
      "name" = "eck-logstash"
      "namespace" = "logstash-eck"
    }
    "spec" = {
      "count" = 1
      "pipelines" = [
        {
          "config.string" = <<-EOT
          input {
            beats {
              port => 5044
              client_inactivity_timeout => 300
            }
          }
          output {
            if [@metadata][pipeline] {
              elasticsearch {
              hosts => ["elasticsearch.christianbingman.com:80"]
              manage_template => false
              index => "%%{[@metadata][beat]}-%%{[@metadata][version]}-%%{+YYYY.MM.dd}"
              pipeline => "%%{[@metadata][pipeline]}"
              }
            } else {
              elasticsearch {
              hosts => ["elasticsearch.christianbingman.com:80"]
              manage_template => false
              index => "%%{[@metadata][beat]}-%%{[@metadata][version]}-%%{+YYYY.MM.dd}"
              }
            }
          }
          
          EOT
          "pipeline.id" = "main"
        },
      ]
      "services" = [
        {
          "name" = "beats"
          "service" = {
            "metadata" = {
              "annotations" = {
                "metallb.universe.tf/loadBalancerIPs" = "10.2.0.28"
              }
            }
            "spec" = {
              "ports" = [
                {
                  "name" = "filebeat"
                  "port" = 5044
                  "protocol" = "TCP"
                  "targetPort" = 5044
                },
              ]
              "type" = "LoadBalancer"
            }
          }
        },
      ]
      "version" = "8.14.0"
    }
  }
}
