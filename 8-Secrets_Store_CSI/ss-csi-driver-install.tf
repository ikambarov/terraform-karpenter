# Deploy Secrets Store CSI Driver via Helm
resource "helm_release" "secrets_store_csi" {
  name       = "secrets-store-csi"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  wait            = true
  timeout         = 600
  cleanup_on_fail = true
}

# Output Secrets Store CSI Driver Helm release metadata
output "secrets_csi_helm_metadata" {
  description = "Metadata of the Secrets Store CSI Driver Helm release"
  value       = helm_release.secrets_store_csi.metadata
}
