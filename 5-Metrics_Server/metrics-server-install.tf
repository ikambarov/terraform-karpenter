# Deploy metrics-server so HPA can read CPU and memory metrics.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.13.1"
  namespace  = "kube-system"

  wait            = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    yamlencode({
      args = [
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
      ]
    })
  ]
}

output "metrics_server_helm_metadata" {
  description = "Metadata of the deployed metrics-server Helm release"
  value       = helm_release.metrics_server.metadata
}
