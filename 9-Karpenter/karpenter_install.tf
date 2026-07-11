# Deploy Karpenter controller via Helm
resource "helm_release" "karpenter_node_controller" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.8.2"
  namespace  = "kube-system"

  create_namespace = false

  set {
    name  = "settings.clusterName"
    value = data.aws_eks_cluster.target.name
  }
  set {
    name  = "settings.clusterEndpoint"
    value = data.aws_eks_cluster.target.endpoint
  }
  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter_node_interruption_queue.name
  }
  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  # Ensure IAM, access, and queue resources exist before deployment
  depends_on = [
    aws_iam_role.karpenter_node_provisioner_role,
    aws_iam_policy.karpenter_node_controller_policy,
    aws_iam_role_policy_attachment.karpenter_node_controller_policy_attach,
    aws_eks_pod_identity_association.karpenter_node_controller_identity,
    aws_eks_access_entry.karpenter_node_ec2_access,
    aws_sqs_queue.karpenter_node_interruption_queue
  ]
}

# Output Helm release metadata
output "karpenter_helm_metadata" {
  description = "Helm release metadata for the Karpenter controller"
  value       = helm_release.karpenter_node_controller.metadata
}
