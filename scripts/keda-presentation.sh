#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEDA_SCRIPT="${ROOT_DIR}/scripts/keda-demo.sh"
KEDA_NAMESPACE="keda"
DEMO_NAMESPACE="keda-demo"

LOAD_DURATION="${LOAD_DURATION:-120}"
LOAD_WORKERS="${LOAD_WORKERS:-6}"
SCALE_OUT_SAMPLES="${SCALE_OUT_SAMPLES:-12}"
SCALE_OUT_INTERVAL="${SCALE_OUT_INTERVAL:-10}"
SCALE_IN_SAMPLES="${SCALE_IN_SAMPLES:-8}"
SCALE_IN_INTERVAL="${SCALE_IN_INTERVAL:-15}"

TOP_SUPPORTED=1
STEP_COUNTER=0

SUPPORTS_COLOR=0
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  if [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    SUPPORTS_COLOR=1
  fi
fi

if (( SUPPORTS_COLOR )); then
  C_RESET=$'\033[0m'
  C_STEP=$'\033[1;35m'
  C_EXPECT=$'\033[1;36m'
  C_INFO=$'\033[1;34m'
  C_WARN=$'\033[1;33m'
  C_ERR=$'\033[1;31m'
  C_SKIP=$'\033[1;32m'
  C_CMD=$'\033[0;32m'
else
  C_RESET=''
  C_STEP=''
  C_EXPECT=''
  C_INFO=''
  C_WARN=''
  C_ERR=''
  C_SKIP=''
  C_CMD=''
fi

log_tag() {
  local tag="$1"
  local color="$2"
  local message="$3"
  printf '%s[%s]%s %s\n' "$color" "$tag" "$C_RESET" "$message"
}

log_info() {
  log_tag "INFO" "$C_INFO" "$1"
}

log_expect() {
  log_tag "EXPECT" "$C_EXPECT" "$1"
}

log_warn() {
  log_tag "WARN" "$C_WARN" "$1" >&2
}

log_skip() {
  log_tag "SKIP" "$C_SKIP" "$1"
}

log_error() {
  log_tag "ERR" "$C_ERR" "$1" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Missing required command: $1"
    exit 1
  fi
}

pause() {
  local prompt="${1:-Press Enter to continue...}"
  local display_prompt="${prompt}"
  if (( SUPPORTS_COLOR )); then
    display_prompt="${C_EXPECT}${prompt}${C_RESET}"
  fi
  if [[ -t 0 ]]; then
    read -rp "$display_prompt" _
  else
    printf '%s\n' "$display_prompt" >&2
    sleep 2
  fi
}

print_step() {
  local title="$1"
  local expectation="${2:-}"
  STEP_COUNTER=$((STEP_COUNTER + 1))
  printf '\n%s=== Step %d: %s ===%s\n' "$C_STEP" "$STEP_COUNTER" "$title" "$C_RESET"
  if [[ -n "$expectation" ]]; then
    log_expect "$expectation"
  fi
}

print_cmd() {
  printf '%s$%s' "$C_CMD" "$C_RESET"
  for arg in "$@"; do
    printf ' %s%q%s' "$C_CMD" "$arg" "$C_RESET"
  done
  printf '\n'
}

run_cmd() {
  print_cmd "$@"
  "$@"
}

namespace_exists() {
  kubectl get ns "$1" >/dev/null 2>&1
}

deployment_exists() {
  kubectl get deploy "$1" -n "$2" >/dev/null 2>&1
}

wait_for_hpa() {
  local attempts=12
  local delay=5
  local attempt

  log_info "Waiting for HPA cpu-api to be created by KEDA..."
  for attempt in $(seq 1 "$attempts"); do
    if kubectl get hpa cpu-api -n "$DEMO_NAMESPACE" >/dev/null 2>&1; then
      log_info "HPA cpu-api detected."
      return 0
    fi
    sleep "$delay"
  done

  log_error "Timed out waiting for HPA cpu-api in namespace ${DEMO_NAMESPACE}"
  exit 1
}

wait_for_cpu_pods_ready() {
  log_info "Waiting for cpu-api pods to reach Ready state..."
  if ! kubectl wait -n "$DEMO_NAMESPACE" --for=condition=Ready pods -l app=cpu-api --timeout=180s >/dev/null 2>&1; then
    log_warn "Timeout waiting for cpu-api pods to become Ready; continuing but investigate pod status."
  else
    log_info "cpu-api pods are Ready."
  fi
}

monitor_scaling() {
  local heading="$1"
  local samples="$2"
  local delay="$3"
  local expectation="${4:-}"
  local i

  printf '\n'
  log_info "$heading"
  if [[ -n "$expectation" ]]; then
    log_expect "$expectation"
  fi
  for i in $(seq 1 "$samples"); do
    printf '\n%s[%s]%s Snapshot %d/%d\n' "$C_INFO" "$(date +%H:%M:%S)" "$C_RESET" "$i" "$samples"
    print_cmd kubectl get hpa cpu-api -n "$DEMO_NAMESPACE"
    if ! kubectl get hpa cpu-api -n "$DEMO_NAMESPACE"; then
      log_warn "Unable to fetch HPA cpu-api; will retry."
    fi
    print_cmd kubectl get deploy cpu-api -n "$DEMO_NAMESPACE"
    if ! kubectl get deploy cpu-api -n "$DEMO_NAMESPACE"; then
      log_warn "Unable to fetch Deployment cpu-api; will retry."
    fi
    if (( TOP_SUPPORTED )); then
      print_cmd kubectl top pods -n "$DEMO_NAMESPACE"
      if ! kubectl top pods -n "$DEMO_NAMESPACE"; then
        log_warn "kubectl top pods failed; skipping pod metrics for the rest of the session."
        TOP_SUPPORTED=0
      fi
    fi
    if (( i < samples )); then
      sleep "$delay"
    fi
  done
}

main() {
  require_command kubectl
  if [[ ! -x "$KEDA_SCRIPT" ]]; then
    log_error "Expected helper script missing: $KEDA_SCRIPT"
    exit 1
  fi

  print_step "Verify or install KEDA core components" \
    $'Expect to see the existing keda namespace or watch the helper install CRDs, the operator, and metrics server so the platform is ready.'
  if namespace_exists "$KEDA_NAMESPACE"; then
    log_skip "Namespace ${KEDA_NAMESPACE} already exists; assuming KEDA is installed."
  else
    run_cmd "$KEDA_SCRIPT" install-all
  fi
  pause "Press Enter after reviewing the install status on screen."

  print_step "Wait for KEDA operator and metrics server to report Available" \
    $'Expect both deployments to reach Available status; this confirms the metrics API is ready to answer HPA queries.'
  run_cmd "$KEDA_SCRIPT" wait
  pause "Press Enter once both deployments report Available."

  print_step "Deploy CPU demo workload managed by KEDA" \
    $'Expect namespace keda-demo, the cpu-api Deployment, Service, and ScaledObject to appear with one ready replica.'
  if deployment_exists "cpu-api" "$DEMO_NAMESPACE"; then
    log_skip "Deployment cpu-api already present in namespace ${DEMO_NAMESPACE}."
  else
    run_cmd "$KEDA_SCRIPT" deploy-cpu-demo
  fi
  run_cmd kubectl rollout status deploy/cpu-api -n "$DEMO_NAMESPACE" --timeout=180s
  wait_for_hpa
  wait_for_cpu_pods_ready
  pause "Press Enter to capture baseline metrics (expect a single idle replica)."

  print_step "Baseline metrics and resources" \
    $'Expect cpu-api to show Desired=1 in the HPA and one ready pod at low CPU before we apply load.'
  log_expect "ScaledObject list should include cpu-api targeting the Deployment."
  run_cmd kubectl get scaledobject -n "$DEMO_NAMESPACE"
  log_expect "HPA list should show cpu-api with DESIRED=1 and TARGET 40% CPU."
  run_cmd kubectl get hpa -n "$DEMO_NAMESPACE"
  log_expect "Pod list should show a single cpu-api pod in Ready state."
  run_cmd kubectl get pods -n "$DEMO_NAMESPACE"
  log_expect "HPA description should highlight minReplicas=1, maxReplicas=10, and the CPU trigger."
  run_cmd kubectl describe hpa cpu-api -n "$DEMO_NAMESPACE"
  log_expect "Pod metrics should remain low while idle (requires metrics server)."
  print_cmd kubectl top pods -n "$DEMO_NAMESPACE"
  if ! kubectl top pods -n "$DEMO_NAMESPACE"; then
    log_warn "kubectl top pods failed (metrics API unavailable?); continuing without live pod metrics."
    TOP_SUPPORTED=0
  fi
  pause "Press Enter to start the autoscaling scenario and watch replicas climb."

  print_step "Trigger CPU load and watch scale-out" \
    $'Expect the CPU load job to push average CPU above 40%% so the HPA raises Desired replicas and new pods roll out.'
  log_info "Launching load job (duration=${LOAD_DURATION}s, workers=${LOAD_WORKERS})."
  "$KEDA_SCRIPT" cpu-load "$LOAD_DURATION" "$LOAD_WORKERS" &
  local load_pid=$!
  monitor_scaling "Scale-out sampling (every ${SCALE_OUT_INTERVAL}s)" \
    "$SCALE_OUT_SAMPLES" "$SCALE_OUT_INTERVAL" \
    $'Desired replicas should climb above 1 while CURRENT CPU stays over the 40%% target; new pods should appear until the metric stabilises.'
  wait "$load_pid"
  log_info "Load job completed."
  pause "Press Enter to monitor the deployment scaling back down to 1 replica."

  print_step "Observe scale-in back to idle" \
    $'Expect Desired replicas to taper back to 1 as CPU falls, with extra pods terminating gracefully.'
  monitor_scaling "Scale-in sampling (every ${SCALE_IN_INTERVAL}s)" \
    "$SCALE_IN_SAMPLES" "$SCALE_IN_INTERVAL" \
    $'Watch Desired replicas return to 1 and observe pods completing/terminating while CURRENT CPU drops under the target.'
  pause "Press Enter to move into cleanup or Q&A mode."

  print_step "Cleanup (optional)" \
    $'Decide whether to remove the demo resources now or leave them running for follow-up questions.'
  if [[ -t 0 ]]; then
    local cleanup_prompt="Remove the CPU demo namespace now? [y/N]: "
    if (( SUPPORTS_COLOR )); then
      cleanup_prompt="${C_EXPECT}${cleanup_prompt}${C_RESET}"
    fi
    read -rp "$cleanup_prompt" answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      run_cmd "$KEDA_SCRIPT" remove-cpu-demo
    else
      log_info "Leaving CPU demo resources in place."
    fi
  else
    log_info "Non-interactive session detected; skipping cleanup prompt."
  fi

  printf '\n%sPresentation workflow complete.%s\n' "$C_STEP" "$C_RESET"
}

main "$@"
