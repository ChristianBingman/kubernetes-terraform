resource "kubernetes_manifest" "filebeat" {
  manifest = {
    "apiVersion" = "beat.k8s.elastic.co/v1beta1"
    "kind" = "Beat"
    "metadata" = {
      "name" = "talos"
      "namespace" = "kube-system"
    }
    "spec" = {
      "config" = {
        "filebeat.inputs" = [
          {
            "paths" = [
              "/var/log/containers/*.log",
            ]
            "type" = "container"
          },
          {
            "host" = "127.0.0.1:12345"
            "processors" = [
              {
                "decode_json_fields" = {
                  "fields" = [
                    "message",
                  ]
                  "target" = ""
                }
              },
              {
                "timestamp" = {
                  "field" = "talos-time"
                  "layouts" = [
                    "2006-01-02T15:04:05.999999999Z07:00",
                  ]
                }
              },
              {
                "drop_fields" = {
                  "fields" = [
                    "message",
                    "talos-time",
                  ]
                }
              },
              {
                "rename" = {
                  "fields" = [
                    {
                      "from" = "msg"
                      "to" = "message"
                    },
                  ]
                }
              },
              {
                "drop_event" = {
                  "when" = {
                    "contains" = {
                      "talos-level" = "info"
                    }
                  }
                }
              },
            ]
            "type" = "udp"
          },
        ]
        "logging.level" = "warning"
        "output.elasticsearch" = {
          "hosts" = [
            "http://elasticsearch.christianbingman.com:80",
          ]
        }
        "setup.ilm.rollover_alias" = "kubernetes"
      }
      "daemonSet" = {
        "podTemplate" = {
          "spec" = {
            "containers" = [
              {
                "name" = "filebeat"
                "ports" = [
                  {
                    "containerPort" = 12345
                    "hostPort" = 12345
                    "protocol" = "UDP"
                  },
                ]
                "volumeMounts" = [
                  {
                    "mountPath" = "/var/log/containers"
                    "name" = "varlogcontainers"
                  },
                  {
                    "mountPath" = "/var/log/pods"
                    "name" = "varlogpods"
                  },
                ]
              },
            ]
            "dnsPolicy" = "ClusterFirstWithHostNet"
            "hostNetwork" = true
            "securityContext" = {
              "runAsUser" = 0
            }
            "tolerations" = [
              {
                "effect" = "NoSchedule"
                "key" = "node-role.kubernetes.io/control-plane"
                "operator" = "Exists"
              },
            ]
            "volumes" = [
              {
                "hostPath" = {
                  "path" = "/var/log/containers"
                }
                "name" = "varlogcontainers"
              },
              {
                "hostPath" = {
                  "path" = "/var/log/pods"
                }
                "name" = "varlogpods"
              },
            ]
          }
        }
        "updateStrategy" = {
          "rollingUpdate" = {
            "maxUnavailable" = "100%"
          }
        }
      }
      "type" = "filebeat"
      "version" = "7.15.1"
    }
  }
}
