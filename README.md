# Kubernetes Platform on Amazon EKS

This repository builds a generic, layered Kubernetes platform on Amazon EKS and deploys the Client Tracker application from a separate application repository.

The project is intentionally organized as independent infrastructure stages so each layer is easy to review, apply, destroy, and extend. Environment-specific values are supplied at runtime through environment variables. Secrets, account IDs, hosted zone names, generated passwords, and Terraform variable files should not be committed.

## Architecture

The platform creates:

- A VPC with public and private subnets.
- An EKS cluster with a small baseline managed node group.
- EKS Pod Identity for AWS-integrated Kubernetes controllers.
- Storage, ingress, DNS, secret, autoscaling, database, monitoring, and observability layers.
- A Helm-based Client Tracker deployment backed by RDS MySQL.

Application traffic flows through Gateway API resources. The AWS Load Balancer Controller provisions the external Application Load Balancer, and ExternalDNS manages Route53 records from the Gateway HTTPRoute.

Runtime secrets are created during deployment:

- RDS master password is managed by AWS RDS and stored in AWS Secrets Manager.
- The app runtime secret is created in Kubernetes from runtime-generated or retrieved values.
- The Grafana admin password is generated at runtime unless explicitly supplied.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `backend.tf` | Bootstraps the S3 bucket used for Terraform remote state. |
| `apply.sh` | Applies all layers in order using temporary runtime tfvars. |
| `destroy.sh` | Destroys all layers in reverse order. |
| `scripts/runtime-config.sh` | Builds runtime configuration from environment variables. |
| `1-VPC` | Network foundation: VPC, subnets, route tables, NAT, and Internet Gateway. |
| `2-EKS` | EKS control plane, baseline managed node group, IAM roles, and subnet tags. |
| `3-Pod_Identity` | EKS Pod Identity Agent add-on. |
| `4-EBS_CSI` | Amazon EBS CSI Driver with Pod Identity. |
| `5-Metrics_Server` | Kubernetes Metrics Server for resource metrics and HPA. |
| `6-AWS_LB_Controller` | AWS Load Balancer Controller and Gateway API CRDs. |
| `7-ExternalDNS` | ExternalDNS EKS add-on with Route53 permissions scoped at runtime. |
| `8-Secrets_Store_CSI` | Secrets Store CSI Driver and AWS provider. |
| `9-Karpenter` | Karpenter controller, interruption queue, node role, NodeClass, and NodePool. |
| `10-Database` | RDS MySQL for Client Tracker. |
| `11-Monitoring` | Prometheus, Grafana, Loki, and Tempo. |
| `12-Observability` | OpenTelemetry Collector gateway and node agents. |
| `13-Client_Tracker` | Values used to deploy the external Client Tracker Helm chart. |

## Layer Order

1. `1-VPC`
2. `2-EKS`
3. `3-Pod_Identity`
4. `4-EBS_CSI`
5. `5-Metrics_Server`
6. `6-AWS_LB_Controller`
7. `7-ExternalDNS`
8. `8-Secrets_Store_CSI`
9. `9-Karpenter`
10. `10-Database`
11. `11-Monitoring`
12. `12-Observability`
13. `13-Client_Tracker`

The root `backend.tf` is applied first by `apply.sh` to create the S3 remote-state bucket. The numbered layers then use S3 state with native lockfiles.

## Local Overrides

The scripts generate temporary tfvars at runtime. To override generated values locally, create `local.tfvars` files:

- Root backend overrides: `local.tfvars`
- Layer overrides: `<layer>/local.tfvars`, for example `2-EKS/local.tfvars`

Local override files are passed after the generated tfvars, so local values win. They are ignored by Git and should stay local to the workstation.

Terraform provider lock files are committed for each root module. They pin provider selections and checksums so every layer initializes consistently on another machine.

## Prerequisites

Install and configure:

- AWS CLI with credentials for the target account.
- Terraform.
- kubectl.
- Helm.
- jq.
- openssl.

The Client Tracker Helm chart is expected at:

```bash
../client_tracker/charts/client-tracker
```

Override the chart location with `CLIENT_TRACKER_REPO_DIR` or `APP_CHART_DIR` if needed.

## Required Runtime Variables

Set these before applying or destroying:

```bash
export AWS_REGION="us-east-1"
export ENVIRONMENT_NAME="dev"
export PROJECT_NAME="eks-dev"
export CLUSTER_NAME="myeks"
```

These values are examples only. Use values appropriate for the target account and environment.

Optional variables:

| Variable | Purpose |
| --- | --- |
| `APP_HOSTNAME` | Public hostname for the Client Tracker Gateway HTTPRoute. |
| `APP_NAMESPACE` | Kubernetes namespace for the app. Defaults to `client-tracker`. |
| `APP_RELEASE_NAME` | Helm release name. Defaults to `client-tracker`. |
| `APP_CHART_DIR` | Path to the Client Tracker Helm chart. |
| `APP_VALUES_FILE` | Values file used for the Client Tracker Helm release. |
| `APP_IMAGE_REPOSITORY` | Optional container image repository override for the app. |
| `APP_IMAGE_TAG` | Optional container image tag override for the app. |
| `GRAFANA_ADMIN_PASSWORD` | Optional Grafana admin password. Generated at runtime when omitted. |
| `HOSTED_ZONE_ID` | Optional Route53 hosted zone ID for ExternalDNS. Auto-discovered from `APP_HOSTNAME` when possible. |
| `EXTERNALDNS_DOMAIN_FILTERS` | Optional ExternalDNS domain filters as a Terraform list literal. |
| `NODE_INSTANCE_TYPES` | Baseline managed node instance types as a Terraform list literal. Defaults to `["t3.medium"]`. |
| `DATABASE_INSTANCE_CLASS` | RDS instance class. Defaults to `db.t4g.micro`. |

## Apply

Deploy the full stack:

```bash
export AWS_REGION="us-east-1"
export ENVIRONMENT_NAME="dev"
export PROJECT_NAME="eks-dev"
export CLUSTER_NAME="myeks"
export APP_HOSTNAME="client-tracker.example.com"

./apply.sh
```

What the script does:

- Creates the remote-state S3 bucket if needed.
- Generates temporary tfvars outside the repository.
- Applies every Terraform layer in order.
- Updates kubeconfig for the created cluster.
- Creates runtime Kubernetes Secrets for Grafana and Client Tracker.
- Retrieves the AWS-managed RDS password at runtime.
- Installs or upgrades the Client Tracker Helm release.

## Verify

Check core health:

```bash
kubectl get nodes
kubectl get pods -A
helm list -A
```

Check the app:

```bash
kubectl -n client-tracker get deploy,job,hpa
kubectl -n client-tracker get gateway,httproute,targetgroupbinding
curl -I "http://${APP_HOSTNAME}/"
```

Check monitoring and observability:

```bash
kubectl -n monitoring get pods
kubectl -n observability get pods
kubectl -n observability logs deploy/otel-gateway --tail=100
kubectl -n observability logs ds/otel-agent-agent --tail=100
```

## Destroy

Destroy the workload and all numbered layers:

```bash
export AWS_REGION="us-east-1"
export ENVIRONMENT_NAME="dev"
export PROJECT_NAME="eks-dev"
export CLUSTER_NAME="myeks"
export APP_HOSTNAME="client-tracker.example.com"

./destroy.sh
```

Also destroy the root backend bucket:

```bash
DESTROY_BACKEND=true ./destroy.sh
```

When `DESTROY_BACKEND=true` is set, the script empties the versioned S3 backend bucket before destroying it.

## Security And Hygiene

Do not commit:

- `*.tfvars` or `*.tfvars.json`.
- `local.tfvars`.
- Terraform state.
- Account IDs.
- Hosted zone names.
- Passwords, API keys, tokens, or generated secrets.
- Environment-specific runtime values.

The deployment flow is designed so runtime values are generated into temporary files and removed automatically. Terraform still stores non-secret resource metadata in remote state because it must track managed infrastructure.

## Notes

- Gateway API is installed in the AWS Load Balancer Controller layer.
- ExternalDNS watches `service`, `ingress`, and `gateway-httproute` sources.
- Karpenter NodeClass manifests are rendered from runtime values before they are applied.
- TLS is not enabled by default. Add it at the application deployment layer when a certificate flow is selected.
- RDS is currently single-instance MySQL for a lab-friendly starting point.
- Monitoring and observability are separate: monitoring covers Prometheus/Grafana/Loki/Tempo, while observability covers OpenTelemetry collection and forwarding.
