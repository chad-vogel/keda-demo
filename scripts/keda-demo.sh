#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEDA_NAMESPACE="keda"
SMOKE_NAMESPACE="keda-test"
DEMO_NAMESPACE="keda-demo"
CURL_IMAGE="${CURL_IMAGE:-curlimages/curl:8.9.1}"
REDIS_IMAGE="${REDIS_IMAGE:-redis:7.4-alpine}"
CPU_API_IMAGE="${CPU_API_IMAGE:-localhost/keda-cpu-api:dev}"
QUEUE_WORKER_IMAGE="${QUEUE_WORKER_IMAGE:-localhost/keda-queue-worker:dev}"
QUEUE_PRODUCER_IMAGE="${QUEUE_PRODUCER_IMAGE:-localhost/keda-queue-producer:dev}"
FUNCTIONS_IMAGE="${FUNCTIONS_IMAGE:-localhost/keda-functions-measure:dev}"

usage() {
  cat <<USAGE
Usage:
  keda-demo.sh install-all            # Apply ./keda (CRDs + operator + metrics-apiserver + admission webhooks)
  keda-demo.sh install-core           # Apply ./keda-core (CRDs + operator + metrics-apiserver)
  keda-demo.sh install-crds           # Apply ./keda-crds (CRDs only)
  keda-demo.sh status                 # Show KEDA namespace, deployments, CRDs, and APIService availability
  keda-demo.sh wait                   # Wait for core KEDA deployments to become Available
  keda-demo.sh smoke-test             # Deploy cron ScaledObject example into keda-test namespace
  keda-demo.sh cleanup-smoke          # Remove smoke-test resources and namespace
  keda-demo.sh deploy-cpu-demo        # Deploy CPU stress API + KEDA scaler into keda-demo
  keda-demo.sh remove-cpu-demo        # Remove CPU stress demo
  keda-demo.sh cpu-load [secs] [pods] # Trigger CPU load job (defaults: 120s, workers=4)
  keda-demo.sh deploy-queue-demo      # Deploy Redis + worker + scaler into keda-demo
  keda-demo.sh remove-queue-demo      # Remove queue backlog demo
  keda-demo.sh enqueue [count] [prefix] [delayMs]  # Push Redis messages (default 100) to keda-demo queue
  keda-demo.sh queue-depth            # Print current Redis queue depth
  keda-demo.sh deploy-functions-demo  # Deploy Azure Functions sample (requires ENABLE_FUNCTIONS_DEMO=1)
  keda-demo.sh remove-functions-demo  # Remove the Azure Functions sample
  keda-demo.sh functions-load [requests] [delayMs]  # Generate HTTP load for the Azure Functions sample (requires ENABLE_FUNCTIONS_DEMO=1)
  keda-demo.sh uninstall-all          # Delete ./keda resources
  keda-demo.sh uninstall-core         # Delete ./keda-core resources
  keda-demo.sh uninstall-crds         # Delete ./keda-crds resources (CRDs must be clean)
  keda-demo.sh help                   # Show this message
USAGE
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERR] Missing required command: $1" >&2
    exit 1
  fi
}

ensure_functions_enabled() {
  if [[ "${ENABLE_FUNCTIONS_DEMO:-}" != "1" ]]; then
    cat <<'MSG' >&2
[ERR] The Azure Functions demo is disabled in this environment.
      Set ENABLE_FUNCTIONS_DEMO=1 and ensure compatible images are available before retrying.
MSG
    exit 1
  fi
}

apply_kustomization() {
  local dir="${ROOT_DIR}/$1"
  if [[ ! -d "$dir" ]]; then
    echo "[ERR] Missing kustomization directory: $dir" >&2
    exit 1
  fi
  kubectl apply --server-side -k "$dir"
}

delete_kustomization() {
  local dir="${ROOT_DIR}/$1"
  if [[ ! -d "$dir" ]]; then
    echo "[ERR] Missing kustomization directory: $dir" >&2
    exit 1
  fi
  kubectl delete -k "$dir"
}

cmd_status() {
  echo "[INFO] Namespace and deployments"
  kubectl get ns "${KEDA_NAMESPACE}" || true
  kubectl get deploy -n "${KEDA_NAMESPACE}" || true
  echo
  echo "[INFO] CRDs"
  kubectl get crd | grep keda.sh || true
  echo
  echo "[INFO] External metrics API availability"
  kubectl get apiservice v1beta1.external.metrics.k8s.io \
    -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || true
  echo
}

cmd_wait() {
  kubectl wait -n "${KEDA_NAMESPACE}" --for=condition=Available deploy/keda-operator --timeout=180s
  kubectl wait -n "${KEDA_NAMESPACE}" --for=condition=Available deploy/keda-metrics-apiserver --timeout=180s
}

cmd_smoke_test() {
  kubectl get ns "${SMOKE_NAMESPACE}" >/dev/null 2>&1 || kubectl create ns "${SMOKE_NAMESPACE}"
  kubectl apply -f "${ROOT_DIR}/manifests/hello-deploy.yaml"
  kubectl apply -f "${ROOT_DIR}/manifests/hello-cron-scaledobject.yaml"
  echo "[INFO] Watch deployment with: kubectl get deploy -n ${SMOKE_NAMESPACE} -w"
}

cmd_cleanup_smoke() {
  kubectl delete -f "${ROOT_DIR}/manifests/hello-cron-scaledobject.yaml" --ignore-not-found
  kubectl delete -f "${ROOT_DIR}/manifests/hello-deploy.yaml" --ignore-not-found
  kubectl delete ns "${SMOKE_NAMESPACE}" --ignore-not-found
}

cmd_deploy_cpu_demo() {
  apply_kustomization manifests/cpu-demo
}

cmd_remove_cpu_demo() {
  delete_kustomization manifests/cpu-demo || true
}

cmd_cpu_load() {
  local duration="${1:-120}"
  local workers="${2:-4}"
  local job_name="cpu-load-$(date +%s)"
  local payload escaped_payload
  printf -v payload '{"DurationSeconds":%d,"Workers":%d}' "${duration}" "${workers}"
  escaped_payload=$(printf '%s' "${payload}" | sed 's/"/\\"/g')

  kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${job_name}
  namespace: ${DEMO_NAMESPACE}
spec:
  ttlSecondsAfterFinished: 180
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: curl
          image: ${CURL_IMAGE}
          args:
            - "-sS"
            - "-X"
            - "POST"
            - "-H"
            - "Content-Type: application/json"
            - "-d"
            - "${escaped_payload}"
            - "http://cpu-api.${DEMO_NAMESPACE}.svc.cluster.local/load"
EOF

  kubectl wait -n "${DEMO_NAMESPACE}" --for=condition=complete job/"${job_name}" --timeout=120s >/dev/null
  echo "[INFO] CPU load job ${job_name} completed"
  kubectl logs -n "${DEMO_NAMESPACE}" job/"${job_name}" || true
}

cmd_deploy_queue_demo() {
  apply_kustomization manifests/queue-demo
}

cmd_remove_queue_demo() {
  delete_kustomization manifests/queue-demo || true
}

cmd_enqueue_messages() {
  local count="${1:-100}"
  local prefix="${2:-msg}"
  local delay="${3:-0}"
  local job_name="queue-producer-$(date +%s)"

  kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${job_name}
  namespace: ${DEMO_NAMESPACE}
spec:
  ttlSecondsAfterFinished: 180
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: producer
          image: ${QUEUE_PRODUCER_IMAGE}
          env:
            - name: Producer__RedisConnectionString
              value: redis:6379
            - name: Producer__QueueKey
              value: keda-demo-queue
            - name: Producer__MessagePrefix
              value: "${prefix}"
            - name: Producer__MessageCount
              value: "${count}"
            - name: Producer__DelayMs
              value: "${delay}"
EOF

  kubectl wait -n "${DEMO_NAMESPACE}" --for=condition=complete job/"${job_name}" --timeout=180s >/dev/null
  echo "[INFO] Enqueue job ${job_name} completed"
  kubectl logs -n "${DEMO_NAMESPACE}" job/"${job_name}" || true
}

cmd_queue_depth() {
  local pod
  pod=$(kubectl get pods -n "${DEMO_NAMESPACE}" -l app=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -z "${pod}" ]]; then
    echo "[ERR] Redis pod not found in namespace ${DEMO_NAMESPACE}" >&2
    exit 1
  fi
  kubectl exec -n "${DEMO_NAMESPACE}" "${pod}" -- redis-cli llen keda-demo-queue
}

cmd_deploy_functions_demo() {
  ensure_functions_enabled
  apply_kustomization manifests/functions-demo
}

cmd_remove_functions_demo() {
  delete_kustomization manifests/functions-demo || true
}

cmd_functions_load() {
  ensure_functions_enabled
  local requests="${1:-200}"
  local delay_ms="${2:-25}"
  local job_name="functions-load-$(date +%s)"
  local delay_seconds

  delay_seconds=$(awk -v d="${delay_ms}" 'BEGIN { printf "%.3f", d / 1000 }')

  kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${job_name}
  namespace: ${DEMO_NAMESPACE}
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: curl
          image: ${CURL_IMAGE}
          command:
            - /bin/sh
            - -c
            - |
              set -euo pipefail
              for i in \\$(seq 1 ${requests}); do
                curl -sS -X POST \
                  -H "Content-Type: application/json" \
                  -d '{"sensorId":"demo","value":42,"iterations":30000,"parallelism":4}' \
                  http://functions-runtime.${DEMO_NAMESPACE}.svc.cluster.local/api/measure >/dev/null
                sleep ${delay_seconds}
              done
EOF

  kubectl wait -n "${DEMO_NAMESPACE}" --for=condition=complete job/"${job_name}" --timeout=300s >/dev/null
  echo "[INFO] Functions load job ${job_name} completed"
  kubectl logs -n "${DEMO_NAMESPACE}" job/"${job_name}" || true
}

main() {
  require_command kubectl
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    install-all)
      apply_kustomization keda
      ;;
    install-core)
      apply_kustomization keda-core
      ;;
    install-crds)
      apply_kustomization keda-crds
      ;;
    uninstall-all)
      delete_kustomization keda
      ;;
    uninstall-core)
      delete_kustomization keda-core
      ;;
    uninstall-crds)
      delete_kustomization keda-crds
      ;;
    status)
      cmd_status
      ;;
    wait)
      cmd_wait
      ;;
    smoke-test)
      cmd_smoke_test
      ;;
    cleanup-smoke)
      cmd_cleanup_smoke
      ;;
    deploy-cpu-demo)
      cmd_deploy_cpu_demo
      ;;
    remove-cpu-demo)
      cmd_remove_cpu_demo
      ;;
    cpu-load)
      cmd_cpu_load "$@"
      ;;
    deploy-queue-demo)
      cmd_deploy_queue_demo
      ;;
    remove-queue-demo)
      cmd_remove_queue_demo
      ;;
    enqueue)
      cmd_enqueue_messages "$@"
      ;;
    queue-depth)
      cmd_queue_depth
      ;;
    deploy-functions-demo)
      cmd_deploy_functions_demo
      ;;
    remove-functions-demo)
      cmd_remove_functions_demo
      ;;
    functions-load)
      cmd_functions_load "$@"
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      echo "[ERR] Unknown command: $cmd" >&2
      echo
      usage
      exit 1
      ;;
  esac
}

main "$@"
