resource "null_resource" "gateway_api_crds" {
  triggers = {
    gateway_api_version = "v1.5.0"
    aws_lbc_crds        = "main"
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
      kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml
      printf '%s\n' \
        'apiVersion: gateway.networking.k8s.io/v1' \
        'kind: GatewayClass' \
        'metadata:' \
        '  name: alb' \
        'spec:' \
        '  controllerName: gateway.k8s.aws/alb' \
        | kubectl apply -f -
    EOT
  }
}
