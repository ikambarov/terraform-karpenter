resource "helm_release" "otel_gateway" {
  name             = "otel-gateway"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = "0.165.0"
  namespace        = "observability"
  create_namespace = true

  values = [
    yamlencode({
      mode             = "deployment"
      fullnameOverride = "otel-gateway"
      image = {
        repository = "otel/opentelemetry-collector-contrib"
      }
      replicaCount = 1
      ports = {
        jaeger-compact = { enabled = false }
        jaeger-thrift  = { enabled = false }
        jaeger-grpc    = { enabled = false }
        zipkin         = { enabled = false }
        metrics        = { enabled = true }
      }
      serviceMonitor = {
        enabled = true
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
      presets = {
        kubernetesAttributes = {
          enabled = true
        }
      }
      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "$${env:MY_POD_IP}:4317"
              }
              http = {
                endpoint = "$${env:MY_POD_IP}:4318"
              }
            }
          }
        }
        processors = {
          memory_limiter = {
            check_interval         = "5s"
            limit_percentage       = 80
            spike_limit_percentage = 25
          }
          resource = {
            attributes = [
              {
                key    = "deployment.environment"
                value  = var.environment_name
                action = "upsert"
              },
              {
                key    = "k8s.cluster.name"
                value  = var.eks_cluster_name
                action = "upsert"
              }
            ]
          }
          batch = {}
        }
        exporters = {
          otlp = {
            endpoint = "tempo.monitoring.svc.cluster.local:4317"
            tls = {
              insecure = true
            }
          }
          otlphttp = {
            endpoint = "http://loki-gateway.monitoring.svc.cluster.local/otlp"
          }
          debug = {}
        }
        service = {
          pipelines = {
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "k8sattributes", "resource", "batch"]
              exporters  = ["otlp"]
            }
            logs = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "k8sattributes", "resource", "batch"]
              exporters  = ["otlphttp"]
            }
            metrics = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "k8sattributes", "resource", "batch"]
              exporters  = ["debug"]
            }
          }
        }
      }
    })
  ]
}

resource "helm_release" "otel_agent" {
  name             = "otel-agent"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = "0.165.0"
  namespace        = "observability"
  create_namespace = true

  values = [
    yamlencode({
      mode             = "daemonset"
      fullnameOverride = "otel-agent"
      image = {
        repository = "otel/opentelemetry-collector-contrib"
      }
      ports = {
        otlp           = { enabled = false }
        otlp-http      = { enabled = false }
        jaeger-compact = { enabled = false }
        jaeger-thrift  = { enabled = false }
        jaeger-grpc    = { enabled = false }
        zipkin         = { enabled = false }
        metrics        = { enabled = true }
      }
      serviceMonitor = {
        enabled = true
      }
      presets = {
        logsCollection = {
          enabled              = true
          includeCollectorLogs = false
        }
        hostMetrics = {
          enabled = true
        }
        kubeletMetrics = {
          enabled = true
        }
        kubernetesAttributes = {
          enabled = true
        }
      }
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
      config = {
        processors = {
          memory_limiter = {
            check_interval         = "5s"
            limit_percentage       = 80
            spike_limit_percentage = 25
          }
          resource = {
            attributes = [
              {
                key    = "deployment.environment"
                value  = var.environment_name
                action = "upsert"
              },
              {
                key    = "k8s.cluster.name"
                value  = var.eks_cluster_name
                action = "upsert"
              }
            ]
          }
          batch = {}
        }
        exporters = {
          otlp = {
            endpoint = "otel-gateway.observability.svc.cluster.local:4317"
            tls = {
              insecure = true
            }
          }
          debug = {}
        }
        service = {
          pipelines = {
            logs = {
              receivers  = ["otlp", "filelog"]
              processors = ["memory_limiter", "k8sattributes", "resource", "batch"]
              exporters  = ["otlp"]
            }
            metrics = {
              receivers  = ["otlp", "hostmetrics", "kubeletstats"]
              processors = ["memory_limiter", "k8sattributes", "resource", "batch"]
              exporters  = ["debug"]
            }
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.otel_gateway
  ]
}

output "otlp_grpc_endpoint" {
  description = "In-cluster OTLP/gRPC endpoint for application telemetry."
  value       = "otel-gateway.observability.svc.cluster.local:4317"
}

output "otlp_http_endpoint" {
  description = "In-cluster OTLP/HTTP endpoint for application telemetry."
  value       = "http://otel-gateway.observability.svc.cluster.local:4318"
}
