#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/scripts/runtime-config.sh"

load_project_config
make_runtime_dir

APP_NAMESPACE="${APP_NAMESPACE:-client-tracker}"
APP_RELEASE_NAME="${APP_RELEASE_NAME:-client-tracker}"
APP_CHART_DIR="${APP_CHART_DIR:-${CLIENT_TRACKER_REPO_DIR:-${ROOT_DIR}/../client_tracker}/charts/client-tracker}"
APP_VALUES_FILE="${APP_VALUES_FILE:-${ROOT_DIR}/13-Client_Tracker/values.yaml}"
APP_RUNTIME_SECRET="${APP_RUNTIME_SECRET:-client-tracker-runtime}"
GRAFANA_NAMESPACE="${GRAFANA_NAMESPACE:-monitoring}"
GRAFANA_ADMIN_SECRET="${GRAFANA_ADMIN_SECRET:-grafana-admin}"

terraform_init_backend() {
  local key="$1"
  mapfile -t backend_args < <(backend_init_args "$key")
  terraform init -reconfigure "${backend_args[@]}"
}

terraform_apply() {
  local dir="$1"
  local key="$2"
  local var_file="$3"
  local override_file="${ROOT_DIR}/${dir}/local.tfvars"
  local -a var_args

  pushd "${ROOT_DIR}/${dir}" >/dev/null
  terraform_init_backend "${key}"
  mapfile -t var_args < <(terraform_var_file_args "${var_file}" "${override_file}")
  terraform apply "${var_args[@]}" -auto-approve
  popd >/dev/null
}

terraform_var_file_args() {
  local generated_file="$1"
  local override_file="$2"

  printf '%s\n' "-var-file=${generated_file}"
  if [[ -f "${override_file}" ]]; then
    printf '%s\n' "-var-file=${override_file}"
  fi
}

apply_secret() {
  local namespace="$1"
  local name="$2"
  local key_one="$3"
  local value_one="$4"
  local key_two="$5"
  local value_two="$6"

  kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f - <<EOF_SECRET
apiVersion: v1
kind: Secret
metadata:
  name: ${name}
  namespace: ${namespace}
type: Opaque
stringData:
  ${key_one}: |-
    ${value_one}
  ${key_two}: |-
    ${value_two}
EOF_SECRET
}

render_karpenter_manifests() {
  local node_role_name="$1"
  local rendered_ec2nodeclass="${RUNTIME_DIR}/ec2nodeclass.yaml"
  local rendered_nodepool="${RUNTIME_DIR}/nodepool.yaml"

  sed \
    -e "s#__KARPENTER_NODE_ROLE_NAME__#${node_role_name}#g" \
    -e "s#__EKS_CLUSTER_NAME__#${EKS_CLUSTER_NAME}#g" \
    "${ROOT_DIR}/9-Karpenter/ec2nodeclass.yaml.tpl" >"${rendered_ec2nodeclass}"
  cp "${ROOT_DIR}/9-Karpenter/nodepool.yaml" "${rendered_nodepool}"

  printf '%s\n' "${rendered_ec2nodeclass}" "${rendered_nodepool}"
}

ROOT_VARS="${RUNTIME_DIR}/root.tfvars"
VPC_VARS="${RUNTIME_DIR}/vpc.tfvars"
EKS_VARS="${RUNTIME_DIR}/eks.tfvars"
COMMON_VARS="${RUNTIME_DIR}/common.tfvars"
EXTERNALDNS_VARS="${RUNTIME_DIR}/externaldns.tfvars"
DATABASE_VARS="${RUNTIME_DIR}/database.tfvars"

write_root_vars "${ROOT_VARS}"
write_vpc_vars "${VPC_VARS}"
write_eks_vars "${EKS_VARS}"
write_common_layer_vars "${COMMON_VARS}"
write_externaldns_vars "${EXTERNALDNS_VARS}"
write_database_vars "${DATABASE_VARS}"

mapfile -t root_var_args < <(terraform_var_file_args "${ROOT_VARS}" "${ROOT_DIR}/local.tfvars")
terraform -chdir="${ROOT_DIR}" init -backend=false
terraform -chdir="${ROOT_DIR}" apply "${root_var_args[@]}" -auto-approve

terraform_apply "1-VPC" "vpc/${ENVIRONMENT_NAME}/terraform.tfstate" "${VPC_VARS}"
terraform_apply "2-EKS" "eks/${ENVIRONMENT_NAME}/terraform.tfstate" "${EKS_VARS}"
aws eks update-kubeconfig --name "${EKS_CLUSTER_NAME}" --region "${AWS_REGION}"
terraform_apply "3-Pod_Identity" "pod-identity/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_apply "4-EBS_CSI" "ebs-csi/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_apply "5-Metrics_Server" "metrics-server/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_apply "6-AWS_LB_Controller" "aws-lb-controller/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_apply "7-ExternalDNS" "externaldns/${ENVIRONMENT_NAME}/terraform.tfstate" "${EXTERNALDNS_VARS}"
terraform_apply "8-Secrets_Store_CSI" "secrets-store-csi/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_apply "9-Karpenter" "karpenter/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"

KARPENTER_NODE_ROLE_NAME="$(terraform -chdir="${ROOT_DIR}/9-Karpenter" output -raw node_role_name)"
mapfile -t karpenter_manifests < <(render_karpenter_manifests "${KARPENTER_NODE_ROLE_NAME}")
kubectl apply -f "${karpenter_manifests[0]}"
kubectl apply -f "${karpenter_manifests[1]}"

terraform_apply "10-Database" "database/${ENVIRONMENT_NAME}/terraform.tfstate" "${DATABASE_VARS}"

GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-$(openssl rand -base64 36)}"
apply_secret "${GRAFANA_NAMESPACE}" "${GRAFANA_ADMIN_SECRET}" \
  "admin-user" "admin" \
  "admin-password" "${GRAFANA_ADMIN_PASSWORD}"

terraform_apply "11-Monitoring" "monitoring/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_apply "12-Observability" "observability/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"

DB_HOST="$(terraform -chdir="${ROOT_DIR}/10-Database" output -raw database_address)"
DB_PORT="$(terraform -chdir="${ROOT_DIR}/10-Database" output -raw database_port)"
DB_NAME="$(terraform -chdir="${ROOT_DIR}/10-Database" output -raw database_name)"
DB_USER="$(terraform -chdir="${ROOT_DIR}/10-Database" output -raw database_username)"
DB_SECRET_ARN="$(terraform -chdir="${ROOT_DIR}/10-Database" output -raw database_secret_arn)"
DB_PASSWORD="$(aws secretsmanager get-secret-value \
  --secret-id "${DB_SECRET_ARN}" \
  --region "${AWS_REGION}" \
  --query SecretString \
  --output text | jq -r '.password')"
DJANGO_SECRET_KEY="$(kubectl get secret "${APP_RUNTIME_SECRET}" \
  --namespace "${APP_NAMESPACE}" \
  -o jsonpath='{.data.DJANGO_SECRET_KEY}' 2>/dev/null | base64 --decode || true)"

if [[ -z "${DJANGO_SECRET_KEY}" ]]; then
  DJANGO_SECRET_KEY="$(openssl rand -base64 48)"
fi

apply_secret "${APP_NAMESPACE}" "${APP_RUNTIME_SECRET}" \
  "DJANGO_SECRET_KEY" "${DJANGO_SECRET_KEY}" \
  "DB_PASSWORD" "${DB_PASSWORD}"

helm_args=(
  upgrade --install "${APP_RELEASE_NAME}" "${APP_CHART_DIR}"
  --namespace "${APP_NAMESPACE}" \
  --create-namespace \
  -f "${APP_VALUES_FILE}" \
  --set database.host="${DB_HOST}" \
  --set database.port="${DB_PORT}" \
  --set database.name="${DB_NAME}" \
  --set database.user="${DB_USER}"
)

if [[ -n "${APP_HOSTNAME:-}" ]]; then
  helm_args+=(--set "gateway.hostnames[0]=${APP_HOSTNAME}")
fi

if [[ -n "${APP_IMAGE_REPOSITORY:-}" ]]; then
  helm_args+=(--set "image.repository=${APP_IMAGE_REPOSITORY}")
fi

if [[ -n "${APP_IMAGE_TAG:-}" ]]; then
  helm_args+=(--set "image.tag=${APP_IMAGE_TAG}")
fi

helm "${helm_args[@]}"
