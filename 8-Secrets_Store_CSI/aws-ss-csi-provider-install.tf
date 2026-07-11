# Deploy AWS Secrets Store CSI Provider via Helm
resource "helm_release" "aws_secrets_store_csi_provider" {
  depends_on = [
    helm_release.secrets_store_csi
  ]

  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"

  set {
    name  = "secrets-store-csi-driver.install"
    value = "false"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  wait            = true
  timeout         = 600
  cleanup_on_fail = true
}

# Output AWS Secrets Store CSI Provider Helm release metadata
output "aws_secrets_csi_provider_metadata" {
  description = "Metadata of the AWS Secrets Store CSI Provider Helm release"
  value       = helm_release.aws_secrets_store_csi_provider.metadata
}
