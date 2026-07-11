resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = "7.0.0"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"
      loki = {
        auth_enabled  = false
        useTestSchema = true
        commonConfig = {
          path_prefix        = "/tmp/loki"
          replication_factor = 1
        }
        storage = {
          type = "filesystem"
          filesystem = {
            chunks_directory = "/tmp/loki/chunks"
            rules_directory  = "/tmp/loki/rules"
          }
        }
        rulerConfig = {
          wal = {
            dir = "/tmp/loki/ruler-wal"
          }
        }
      }
      singleBinary = {
        replicas = 1
        persistence = {
          enabled = false
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "768Mi"
          }
        }
      }
      read = {
        replicas = 0
      }
      write = {
        replicas = 0
      }
      backend = {
        replicas = 0
      }
      chunksCache = {
        enabled = false
      }
      resultsCache = {
        enabled = false
      }
      gateway = {
        enabled = true
      }
      lokiCanary = {
        enabled = false
      }
      test = {
        enabled = false
      }
    })
  ]

  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "tempo" {
  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  version          = "1.24.4"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      tempo = {
        memBallastSizeMbs = 128
        retention         = "24h"
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "768Mi"
          }
        }
      }
      persistence = {
        enabled = false
      }
      serviceMonitor = {
        enabled = true
      }
    })
  ]

  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "87.14.0"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        admin = {
          existingSecret = "grafana-admin"
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }
        additionalDataSources = [
          {
            name      = "Loki"
            type      = "loki"
            access    = "proxy"
            url       = "http://loki-gateway.monitoring.svc.cluster.local"
            isDefault = false
          },
          {
            name   = "Tempo"
            type   = "tempo"
            uid    = "tempo"
            access = "proxy"
            url    = "http://tempo.monitoring.svc.cluster.local:3200"
          }
        ]
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      prometheus = {
        prometheusSpec = {
          retention = "24h"
          resources = {
            requests = {
              cpu    = "200m"
              memory = "768Mi"
            }
            limits = {
              cpu    = "1"
              memory = "1536Mi"
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {}
          resources = {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    })
  ]

}
