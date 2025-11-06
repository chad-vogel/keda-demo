#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEDA_NAMESPACE="keda"
KEDA_DEMO_NAMESPACE="keda-demo"
SMOKE_NAMESPACE="keda-test"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-keda-demo}"
DELETE_KIND_CLUSTER=false

usage() {
  cat <<USAGE
Usage: keda-demo-tear-down.sh [options]

Options:
  --delete-kind-cluster   Delete the kind cluster (name defaults to 'keda-demo'
                          or \$KIND_CLUSTER_NAME if set)
  -h, --help              Show this help message

This script removes the demo workloads, smoke test, and KEDA itself from the
current Kubernetes context. It is idempotent and ignores resources that are
already absent.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete-kind-cluster)
      DELETE_KIND_CLUSTER=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERR] Unknown option: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERR] Missing required command: $1" >&2
    exit 1
  fi
}

require_command kubectl

delete_if_exists() {
  local description="$1"
  shift

  echo "[INFO] ${description}"
  if ! "$@"; then
    echo "[WARN] Command failed (continuing): $*" >&2
  fi
}

delete_if_exists "Removing queue demo resources (namespace: ${KEDA_DEMO_NAMESPACE})" \
  kubectl delete --ignore-not-found -k "${ROOT_DIR}/manifests/queue-demo"

delete_if_exists "Removing CPU demo resources (namespace: ${KEDA_DEMO_NAMESPACE})" \
  kubectl delete --ignore-not-found -k "${ROOT_DIR}/manifests/cpu-demo"

delete_if_exists "Removing cron smoke-test resources (namespace: ${SMOKE_NAMESPACE})" \
  kubectl delete --ignore-not-found \
    -f "${ROOT_DIR}/manifests/hello-cron-scaledobject.yaml" \
    -f "${ROOT_DIR}/manifests/hello-deploy.yaml"

delete_if_exists "Deleting smoke-test namespace ${SMOKE_NAMESPACE}" \
  kubectl delete ns "${SMOKE_NAMESPACE}" --ignore-not-found

delete_if_exists "Deleting demo namespace ${KEDA_DEMO_NAMESPACE}" \
  kubectl delete ns "${KEDA_DEMO_NAMESPACE}" --ignore-not-found

delete_if_exists "Uninstalling KEDA (namespace: ${KEDA_NAMESPACE})" \
  kubectl delete --ignore-not-found -k "${ROOT_DIR}/keda"

delete_if_exists "Deleting KEDA namespace ${KEDA_NAMESPACE}" \
  kubectl delete ns "${KEDA_NAMESPACE}" --ignore-not-found

if "$DELETE_KIND_CLUSTER"; then
  require_command kind
  delete_if_exists "Deleting kind cluster '${KIND_CLUSTER_NAME}'" \
    kind delete cluster --name "${KIND_CLUSTER_NAME}"
fi

echo "[INFO] Teardown complete"
