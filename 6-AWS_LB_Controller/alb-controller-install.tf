# Deploy AWS ALB Controller via Helm
resource "helm_release" "alb_controller" {
  depends_on = [
    null_resource.gateway_api_crds,
    aws_iam_role.alb_controller_role,
    aws_eks_pod_identity_association.alb_controller
  ]

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.4.1"
  namespace  = "kube-system"

  wait            = true
  timeout         = 600
  cleanup_on_fail = true

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.target.id
  }

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.target.vpc_config[0].vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }
}

# Output Helm release metadata
output "alb_controller_helm_metadata" {
  description = "Metadata of the deployed ALB Controller Helm release"
  value       = helm_release.alb_controller.metadata
}
