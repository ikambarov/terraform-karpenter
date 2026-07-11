#!/usr/bin/env bash
set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Set ${name} before running this script." >&2
    exit 1
  fi
}

load_project_config() {
  require_env AWS_REGION
  require_env ENVIRONMENT_NAME
  require_env PROJECT_NAME
  require_env CLUSTER_NAME

  AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
  EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-${ENVIRONMENT_NAME}-${CLUSTER_NAME}}"
  VPC_NAME="${VPC_NAME:-${ENVIRONMENT_NAME}-vpc}"
  BACKEND_BUCKET="${BACKEND_BUCKET:-tfstate-${AWS_ACCOUNT_ID}-${AWS_REGION}-${PROJECT_NAME}}"

  VPC_NETWORK_CIDR="${VPC_NETWORK_CIDR:-10.0.0.0/16}"
  SUBNET_MASK_BITS="${SUBNET_MASK_BITS:-8}"
  CLUSTER_SERVICE_IPV4_CIDR="${CLUSTER_SERVICE_IPV4_CIDR:-172.20.0.0/16}"
  CLUSTER_VERSION="${CLUSTER_VERSION:-1.34}"
  CLUSTER_ENDPOINT_PUBLIC_ACCESS="${CLUSTER_ENDPOINT_PUBLIC_ACCESS:-true}"
  CLUSTER_ENDPOINT_PUBLIC_ACCESS_CIDRS="${CLUSTER_ENDPOINT_PUBLIC_ACCESS_CIDRS:-[\"0.0.0.0/0\"]}"
  NODE_INSTANCE_TYPES="${NODE_INSTANCE_TYPES:-[\"t3.medium\"]}"
  NODE_CAPACITY_TYPE="${NODE_CAPACITY_TYPE:-ON_DEMAND}"
  NODE_DISK_SIZE="${NODE_DISK_SIZE:-40}"

  DATABASE_NAME="${DATABASE_NAME:-client_tracker}"
  DATABASE_USERNAME="${DATABASE_USERNAME:-admin}"
  DATABASE_INSTANCE_CLASS="${DATABASE_INSTANCE_CLASS:-db.t4g.micro}"
  DATABASE_ALLOCATED_STORAGE="${DATABASE_ALLOCATED_STORAGE:-20}"

  COMMON_TAGS_FILE="${COMMON_TAGS_FILE:-}"

  configure_dns_runtime
}

configure_dns_runtime() {
  local hosted_zone_was_set="${HOSTED_ZONE_ID+x}"
  local domain_filters_was_set="${EXTERNALDNS_DOMAIN_FILTERS+x}"

  HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
  EXTERNALDNS_DOMAIN_FILTERS="${EXTERNALDNS_DOMAIN_FILTERS:-[]}"
  EXTERNALDNS_SOURCES="${EXTERNALDNS_SOURCES:-[\"service\",\"ingress\",\"gateway-httproute\"]}"

  if [[ -z "${APP_HOSTNAME:-}" ]]; then
    return
  fi

  if [[ -n "${hosted_zone_was_set}" && -n "${domain_filters_was_set}" ]]; then
    return
  fi

  local candidate="${APP_HOSTNAME%.}"
  while [[ -n "${candidate}" ]]; do
    local zones_json zone_id zone_name
    zones_json="$(aws route53 list-hosted-zones-by-name \
      --dns-name "${candidate}." \
      --max-items 1 \
      --output json)"
    zone_id="$(printf '%s' "${zones_json}" | jq -r --arg name "${candidate}." '.HostedZones[]? | select(.Name == $name) | .Id' | head -n1)"
    zone_name="$(printf '%s' "${zones_json}" | jq -r --arg name "${candidate}." '.HostedZones[]? | select(.Name == $name) | .Name' | head -n1)"

    if [[ -n "${zone_id}" && "${zone_id}" != "null" ]]; then
      if [[ -z "${hosted_zone_was_set}" ]]; then
        HOSTED_ZONE_ID="${zone_id##*/}"
      fi
      if [[ -z "${domain_filters_was_set}" ]]; then
        EXTERNALDNS_DOMAIN_FILTERS="[\"${zone_name%.}\"]"
      fi
      return
    fi

    if [[ "${candidate}" != *.* ]]; then
      break
    fi
    candidate="${candidate#*.}"
  done
}

write_common_tags() {
  if [[ -n "${COMMON_TAGS_FILE}" ]]; then
    cat "${COMMON_TAGS_FILE}"
    return
  fi

  cat <<EOF_TAGS
{
  managed_by   = "terraform"
  project_name = "${PROJECT_NAME}"
  environment  = "${ENVIRONMENT_NAME}"
}
EOF_TAGS
}

make_runtime_dir() {
  RUNTIME_DIR="$(mktemp -d)"
  trap 'rm -rf "${RUNTIME_DIR}"' EXIT
}

write_root_vars() {
  local file="$1"
  cat >"${file}" <<EOF_VARS
aws_region          = "${AWS_REGION}"
project_name        = "${PROJECT_NAME}"
environment_name    = "${ENVIRONMENT_NAME}"
backend_bucket_name = "${BACKEND_BUCKET}"
common_tags         = $(write_common_tags)
EOF_VARS
}

write_vpc_vars() {
  local file="$1"
  cat >"${file}" <<EOF_VARS
aws_region       = "${AWS_REGION}"
environment_name = "${ENVIRONMENT_NAME}"
cluster_name     = "${CLUSTER_NAME}"
vpc_network_cidr = "${VPC_NETWORK_CIDR}"
subnet_mask_bits = ${SUBNET_MASK_BITS}
tags             = $(write_common_tags)
EOF_VARS
}

write_eks_vars() {
  local file="$1"
  cat >"${file}" <<EOF_VARS
aws_region                            = "${AWS_REGION}"
environment_name                      = "${ENVIRONMENT_NAME}"
vpc_name                              = "${VPC_NAME}"
cluster_name                          = "${CLUSTER_NAME}"
cluster_version                       = "${CLUSTER_VERSION}"
cluster_service_ipv4_cidr             = "${CLUSTER_SERVICE_IPV4_CIDR}"
cluster_endpoint_public_access        = ${CLUSTER_ENDPOINT_PUBLIC_ACCESS}
cluster_endpoint_public_access_cidrs  = ${CLUSTER_ENDPOINT_PUBLIC_ACCESS_CIDRS}
node_instance_types                   = ${NODE_INSTANCE_TYPES}
node_capacity_type                    = "${NODE_CAPACITY_TYPE}"
node_disk_size                        = ${NODE_DISK_SIZE}
common_tags                           = $(write_common_tags)
EOF_VARS
}

write_common_layer_vars() {
  local file="$1"
  cat >"${file}" <<EOF_VARS
aws_region       = "${AWS_REGION}"
environment_name = "${ENVIRONMENT_NAME}"
eks_cluster_name = "${EKS_CLUSTER_NAME}"
common_tags      = $(write_common_tags)
EOF_VARS
}

write_externaldns_vars() {
  local file="$1"
  cat >"${file}" <<EOF_VARS
aws_region       = "${AWS_REGION}"
environment_name = "${ENVIRONMENT_NAME}"
eks_cluster_name = "${EKS_CLUSTER_NAME}"
common_tags      = $(write_common_tags)
hosted_zone_id   = "${HOSTED_ZONE_ID}"
domain_filters   = ${EXTERNALDNS_DOMAIN_FILTERS}
sources          = ${EXTERNALDNS_SOURCES}
EOF_VARS
}

write_database_vars() {
  local file="$1"
  cat >"${file}" <<EOF_VARS
aws_region        = "${AWS_REGION}"
environment_name  = "${ENVIRONMENT_NAME}"
vpc_name          = "${VPC_NAME}"
eks_cluster_name  = "${EKS_CLUSTER_NAME}"
database_name     = "${DATABASE_NAME}"
database_username = "${DATABASE_USERNAME}"
instance_class    = "${DATABASE_INSTANCE_CLASS}"
allocated_storage = ${DATABASE_ALLOCATED_STORAGE}
common_tags       = $(write_common_tags)
EOF_VARS
}

backend_init_args() {
  local key="$1"
  printf '%s\n' \
    "-backend-config=bucket=${BACKEND_BUCKET}" \
    "-backend-config=key=${key}" \
    "-backend-config=region=${AWS_REGION}" \
    "-backend-config=encrypt=true" \
    "-backend-config=use_lockfile=true"
}
