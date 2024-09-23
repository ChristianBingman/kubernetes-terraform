resource "helm_release" "prometheus-stack" {
  name = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  namespace = "prometheus-stack"
  create_namespace = true

  values = [
    <<-EOT
    prometheusOperator:
      logLevel: warn
    prometheus:
      prometheusSpec:
        podMonitorNamespaceSelector: {}
        podMonitorSelector: {}
        podMonitorSelectorNilUsesHelmValues: false
        ruleNamespaceSelector: {}
        ruleSelector: {}
        ruleSelectorNilUsesHelmValues: false
        serviceMonitorNamespaceSelector: {}
        serviceMonitorSelector: {}
        serviceMonitorSelectorNilUsesHelmValues: false
        retention: 1y
        retentionSize: 10GB
        storageSpec:
          volumeClaimTemplate:
            spec:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi
        additionalScrapeConfigs:
          - job_name: "pushgateway-prod"
            scrape_interval: "15s"
            honor_labels: true
            static_configs:
              - targets:
                - "pushgateway-http"
          - job_name: "apcupsd"
            scrape_interval: "15s"
            static_configs:
              - targets:
                - "wolverine.christianbingman.com:9162"
          - job_name: "netdata_all_hosts"
            scrape_interval: "15s"
            metrics_path: "/api/v1/allmetrics"
            honor_labels: true
            params:
              format:
                - "prometheus"
            static_configs:
              - targets:
                - "thor.christianbingman.com:19999"
                - "humantorch.christianbingman.com:19999"
                - "ironman.christianbingman.com:19999"
                - "wolverine.christianbingman.com:19999"
                - "doctorstrange.christianbingman.com:19999"
                - "professorx.christianbingman.com:19999"
                - "buckybarnes.christianbingman.com:19999"
    grafana:
      assertNoLeakedSecrets: false
      sidecar:
        alerts:
          enabled: true
          searchNamespace: ALL
      alerting:
        contactpoints.yaml:
          apiVersion: 1
          contactPoints:
            - orgId: 1
              name: Default Mail
              receivers:
                - uid: default-mail
                  type: email
                  settings:
                    addresses: alerts@christianbingman.com
      grafana.ini:
        smtp:
          enabled: true
          host: ${var.smtp_host}
          user: ${var.smtp_user}
          password: ${var.smtp_pass}
          from_address: ${var.smtp_from_address}
          from_name: ${var.smtp_from_name}
      adminPassword: ${var.admin_password}
      additionalDataSources:
        - name: Elasticsearch (filebeat-*)
          type: elasticsearch
          access: proxy
          url: http://elasticsearch.christianbingman.com
          editable: false
          version: 1
          jsonData:
            index: "filebeat-*"
            timeField: '@timestamp'
        - name: Elasticsearch (kubernetes-*)
          type: elasticsearch
          access: proxy
          url: http://elasticsearch.christianbingman.com
          editable: false
          version: 1
          jsonData:
            index: "kubernetes-*"
            timeField: '@timestamp'
    EOT
  ]
}
