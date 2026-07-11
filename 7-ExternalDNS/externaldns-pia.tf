# Associate ExternalDNS service account with IAM role via Pod Identity
resource "aws_eks_pod_identity_association" "dns_controller" {
  cluster_name    = data.aws_eks_cluster.target.name
  namespace       = "external-dns"
  service_account = "external-dns"
  role_arn        = aws_iam_role.dns_controller_role.arn
}

# Output Pod Identity Association ID for ExternalDNS
output "dns_controller_pod_identity_id" {
  description = "ID of the ExternalDNS Pod Identity Association"
  value       = aws_eks_pod_identity_association.dns_controller.id
}