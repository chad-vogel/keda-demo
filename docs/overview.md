# Demo Overview

This guide is aimed at mid-to-senior application engineers who want to experience [Kubernetes Event-Driven Autoscaling (KEDA)](https://keda.sh/) without deep Kubernetes operations knowledge. We package the official KEDA v2.17.2 release along with three small .NET workloads so you can see event-driven autoscaling in action using familiar `kubectl` commands.

If Kubernetes terminology is new to you, the following short primers are helpful:

- [What is Kubernetes?](https://kubernetes.io/docs/concepts/overview/) – high-level platform concepts.
- [Workloads and Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) – how containers run inside the cluster.
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) – native scaling mechanism that KEDA builds on.

Throughout this document we call out what each command does so you can connect the dots between the script and the underlying Kubernetes resources.

## Prerequisites

- A Kubernetes cluster you can reach with `kubectl`. If you need a local cluster, follow [docs/setup.md](setup.md).
- `kubectl` v1.21 or newer (tested with v1.34). Check with `kubectl version --client`.
- Podman, Docker, or any OCI-compatible image builder. The examples use [Podman](https://podman.io/), but you can substitute your preferred tool.
- Optional: outbound network access to `github.com` (necessary if you fetch manifests directly from GitHub).

## Quickstart

The helper script orchestrates the full KEDA lifecycle. Run the following commands from the repository root:

```bash
# Inspect available commands and descriptions
./scripts/keda-demo.sh help

# Install Custom Resource Definitions (CRDs), operator, metrics API server, and webhooks into the cluster
./scripts/keda-demo.sh install-all

# Wait for the KEDA operator and metrics server deployments to become healthy
./scripts/keda-demo.sh wait

# Show namespaces, deployments, CRDs, and the external metrics application programming interface (API) status
./scripts/keda-demo.sh status

# Deploy the cron-based smoke test and watch it scale during its active window
./scripts/keda-demo.sh smoke-test
kubectl get deploy -n keda-test -w   # Observe replicas toggling between 0 and 1
```

Once you have built the sample images (next section), deploy the CPU and Redis queue demos:

```bash
./scripts/keda-demo.sh deploy-cpu-demo       # ASP.NET API + CPU ScaledObject
./scripts/keda-demo.sh cpu-load 120 4        # Fire a load job (120 seconds, 4 workers)
./scripts/keda-demo.sh deploy-queue-demo     # Redis + worker + Redis ScaledObject
./scripts/keda-demo.sh enqueue 200           # Enqueue 200 messages to drive scaling
```

Use `remove-cpu-demo` and `remove-queue-demo` to remove those workloads. When you are finished with everything, run `./scripts/keda-demo-tear-down.sh --delete-kind-cluster` to clean up the cluster as well.

The Azure Functions sample remains in the repository for reference but is disabled in the helper script by default. If you have access to an AMD64-capable image builder, export `ENABLE_FUNCTIONS_DEMO=1` before using the functions commands.

## Build the Demo Images

Both sample applications live under `src/` and target .NET 9.0. Build container images locally so the cluster can run them:

```bash
CONTAINER_TOOL=${CONTAINER_TOOL:-podman}   # use docker/nerdctl if you prefer
$CONTAINER_TOOL build -t localhost/keda-cpu-api:dev -f src/cpu-api/Dockerfile .
$CONTAINER_TOOL build -t localhost/keda-queue-worker:dev -f src/queue-worker/Dockerfile .
$CONTAINER_TOOL build -t localhost/keda-queue-producer:dev -f src/queue-producer/Dockerfile .
$CONTAINER_TOOL build -t localhost/keda-functions-measure:dev -f src/functions-measure/Dockerfile .   # optional; requires an AMD64-capable builder
# Optional: if using kind, load the images into the nodes
# kind load docker-image localhost/keda-cpu-api:dev
# kind load docker-image localhost/keda-queue-worker:dev
# kind load docker-image localhost/keda-queue-producer:dev
# kind load docker-image localhost/keda-functions-measure:dev
```

The manifests and helper script default to these `localhost/...` tags. If you push the images to a registry, set the `CPU_API_IMAGE`, `QUEUE_WORKER_IMAGE`, and `QUEUE_PRODUCER_IMAGE` environment variables when running the script (or edit the manifests).

## Demo Workloads

Each scenario demonstrates a different KEDA trigger type. Feel free to dip into the manifests under `manifests/` as you follow along.

### Cron Smoke Test

- **What it does:** Scales a deployment between zero and one replica during the first five minutes of every hour (Coordinated Universal Time, UTC).
- **Why it matters:** Showcases KEDA’s ability to scale *to zero* when no work is scheduled.
- **How to run:**

  ```bash
  ./scripts/keda-demo.sh smoke-test
  kubectl get deploy -n keda-test -w
  ```

  Clean up with `./scripts/keda-demo.sh cleanup-smoke`.

### CPU Autoscaling Demo (ASP.NET Core)

- **What it does:** Runs an ASP.NET API (`src/cpu-api/`) fronted by a KEDA `ScaledObject` that reacts to Central Processing Unit (CPU) utilisation.
- **Why it matters:** Demonstrates how KEDA wraps the native HPA to scale traditional HTTP workloads.
- **How to run:**

  ```bash
  ./scripts/keda-demo.sh deploy-cpu-demo
  ./scripts/keda-demo.sh cpu-load 180 6      # duration (seconds), worker threads
  kubectl get hpa -n keda-demo cpu-api -w
  kubectl logs -n keda-demo deploy/cpu-api --tail=20
  ./scripts/keda-demo.sh remove-cpu-demo
  ```

  Tune the JavaScript Object Notation (JSON) payload sent to `/load` to change the duration or number of worker threads. Adjust resource requests and limits in `manifests/cpu-demo/deployment.yaml` to simulate tighter or looser CPU budgets.

### Redis Queue Autoscaling Demo (.NET Worker)

- **What it does:** Deploys Redis, a queue worker (`src/queue-worker/`), and a KEDA Redis trigger that scales based on list length.
- **Why it matters:** Demonstrates event-driven scaling driven by backlog, with scale-to-zero during idle periods.
- **How to run:**

  ```bash
  ./scripts/keda-demo.sh deploy-queue-demo
  ./scripts/keda-demo.sh enqueue 200 backlog 100
  kubectl get deploy -n keda-demo queue-worker -w
  ./scripts/keda-demo.sh queue-depth
  kubectl logs -n keda-demo deploy/queue-worker --tail=20
  ./scripts/keda-demo.sh remove-queue-demo
  ```

  The `enqueue` helper accepts optional `count`, `prefix`, and `delayMs` parameters. To drive load from your workstation instead of in-cluster:

  ```bash
  Producer__RedisConnectionString=localhost:6379 \
    dotnet run --project src/queue-producer -- --count 50 --prefix local --delay 100
  ```

  Tweak scaling thresholds via `manifests/queue-demo/scaledobject.yaml` (`listLength`, `activationThreshold`) and throughput via `Queue__ProcessingDelayMs` inside `manifests/queue-demo/worker-deployment.yaml`.

### Azure Functions Autoscaling Demo (HTTP) *(optional)*

- **What it does:** Packages an Azure Functions isolated worker (`src/functions-measure/`) inside a container and scales it via CPU utilisation.
- **Why it matters:** Demonstrates running the Azure Functions runtime on Kubernetes with KEDA, aligning with the presentation content.
- **Prerequisites:** The official base image (`mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0`) only ships AMD64 layers. Build the container on an x64 host, through an emulation-capable builder, or push a pre-built image to a registry that your cluster can pull from. Enable the demo by exporting `ENABLE_FUNCTIONS_DEMO=1` before invoking the helper script.
- **How to run:**

  ```bash
  ENABLE_FUNCTIONS_DEMO=1 ./scripts/keda-demo.sh deploy-functions-demo
  ENABLE_FUNCTIONS_DEMO=1 ./scripts/keda-demo.sh functions-load 400 25   # requests, delay (ms)
  kubectl get deploy -n keda-demo functions-runtime -w
  kubectl logs -n keda-demo deploy/functions-runtime --tail=20
  ./scripts/keda-demo.sh remove-functions-demo
  ```

  Adjust the JSON payload inside `cmd_functions_load` or run your own traffic generator against the service (`functions-runtime.keda-demo.svc.cluster.local/api/measure`).

### Optional: Vue 3 Dashboard

The folder `web/keda-dashboard/` contains a Vite + Vue 3 (TypeScript) single-page application that showcases how a front-end can surface KEDA status.

```bash
cd web/keda-dashboard
npm install
VITE_KEDA_DEMO_API=http://localhost:8080 npm run dev
```

Use a lightweight proxy (or port-forward) that exposes `/api/workloads` and `/api/metrics` endpoints to feed the UI.

## Teardown

```bash
./scripts/keda-demo-tear-down.sh                 # Removes demos and KEDA components
./scripts/keda-demo-tear-down.sh --delete-kind-cluster   # Also deletes the kind cluster
```

The teardown script is safe to run multiple times; it ignores resources that are already gone. If you ever want to inspect the cluster manually, the following commands are read-only and non-destructive:

```bash
kubectl get ns
kubectl get deploy -A
kubectl get scaledobject -A
kubectl describe scaledobject -n keda-demo cpu-api   # view trigger configuration
```
