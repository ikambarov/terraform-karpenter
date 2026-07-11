#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/scripts/runtime-config.sh"

load_project_config
make_runtime_dir

APP_NAMESPACE="${APP_NAMESPACE:-client-tracker}"
APP_RELEASE_NAME="${APP_RELEASE_NAME:-client-tracker}"
DESTROY_BACKEND="${DESTROY_BACKEND:-false}"

terraform_init_backend() {
  local key="$1"
  mapfile -t backend_args < <(backend_init_args "$key")
  terraform init -reconfigure "${backend_args[@]}"
}

terraform_destroy() {
  local dir="$1"
  local key="$2"
  local var_file="$3"
  local override_file="${ROOT_DIR}/${dir}/local.tfvars"
  local -a var_args

  pushd "${ROOT_DIR}/${dir}" >/dev/null
  terraform_init_backend "${key}"
  mapfile -t var_args < <(terraform_var_file_args "${var_file}" "${override_file}")
  terraform destroy "${var_args[@]}" -auto-approve
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

render_karpenter_manifests() {
  local node_role_name="${ENVIRONMENT_NAME}-karpenter-node-instance-role"
  local rendered_ec2nodeclass="${RUNTIME_DIR}/ec2nodeclass.yaml"
  local rendered_nodepool="${RUNTIME_DIR}/nodepool.yaml"

  sed \
    -e "s#__KARPENTER_NODE_ROLE_NAME__#${node_role_name}#g" \
    -e "s#__EKS_CLUSTER_NAME__#${EKS_CLUSTER_NAME}#g" \
    "${ROOT_DIR}/9-Karpenter/ec2nodeclass.yaml.tpl" >"${rendered_ec2nodeclass}"
  cp "${ROOT_DIR}/9-Karpenter/nodepool.yaml" "${rendered_nodepool}"

  printf '%s\n' "${rendered_ec2nodeclass}" "${rendered_nodepool}"
}

empty_backend_bucket() {
  local versions_json
  local version_count

  versions_json="$(aws s3api list-object-versions --bucket "${BACKEND_BUCKET}" --region "${AWS_REGION}" --output json 2>/dev/null || true)"
  if [[ -z "${versions_json}" ]]; then
    return
  fi

  version_count="$(printf '%s' "${versions_json}" | jq '([.Versions[]?] + [.DeleteMarkers[]?]) | length')"
  if [[ "${version_count}" -gt 0 ]]; then
    printf '%s' "${versions_json}" \
      | jq '{Objects: (([.Versions[]?] + [.DeleteMarkers[]?]) | map({Key, VersionId})), Quiet: true}' \
      >"${RUNTIME_DIR}/delete-objects.json"
    aws s3api delete-objects \
      --bucket "${BACKEND_BUCKET}" \
      --region "${AWS_REGION}" \
      --delete "file://${RUNTIME_DIR}/delete-objects.json" >/dev/null
  fi
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

helm uninstall "${APP_RELEASE_NAME}" --namespace "${APP_NAMESPACE}" --ignore-not-found || true
mapfile -t karpenter_manifests < <(render_karpenter_manifests)
kubectl delete -f "${karpenter_manifests[1]}" --ignore-not-found || true
kubectl delete -f "${karpenter_manifests[0]}" --ignore-not-found || true

terraform_destroy "12-Observability" "observability/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "11-Monitoring" "monitoring/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "10-Database" "database/${ENVIRONMENT_NAME}/terraform.tfstate" "${DATABASE_VARS}"
terraform_destroy "9-Karpenter" "karpenter/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "8-Secrets_Store_CSI" "secrets-store-csi/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "7-ExternalDNS" "externaldns/${ENVIRONMENT_NAME}/terraform.tfstate" "${EXTERNALDNS_VARS}"
terraform_destroy "6-AWS_LB_Controller" "aws-lb-controller/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "5-Metrics_Server" "metrics-server/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "4-EBS_CSI" "ebs-csi/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "3-Pod_Identity" "pod-identity/${ENVIRONMENT_NAME}/terraform.tfstate" "${COMMON_VARS}"
terraform_destroy "2-EKS" "eks/${ENVIRONMENT_NAME}/terraform.tfstate" "${EKS_VARS}"
terraform_destroy "1-VPC" "vpc/${ENVIRONMENT_NAME}/terraform.tfstate" "${VPC_VARS}"

if [[ "${DESTROY_BACKEND}" == "true" ]]; then
  empty_backend_bucket
  mapfile -t root_var_args < <(terraform_var_file_args "${ROOT_VARS}" "${ROOT_DIR}/local.tfvars")
  terraform -chdir="${ROOT_DIR}" init -backend=false
  terraform -chdir="${ROOT_DIR}" destroy "${root_var_args[@]}" -auto-approve
fi
