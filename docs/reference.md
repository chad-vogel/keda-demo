# Reference & Manual Operations

This section collects “just the facts” for teams that prefer running individual commands themselves. It also includes brief definitions of the Kubernetes terms you will encounter so engineers without a platform background can follow along.

## Key Terminology

- **Namespace** – a logical grouping of Kubernetes resources. Think of it as an environment or folder. [Docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- **Deployment** – manages a set of identical pods (replicas) and keeps them running. [Docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- **Horizontal Pod Autoscaler (HPA)** – Kubernetes controller that adjusts replica counts based on metrics. [Docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- **CustomResourceDefinition (CRD)** – mechanism that lets KEDA add new resource types (e.g., `ScaledObject`) to Kubernetes. [Docs](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- **Kustomize** – a configuration tool built into `kubectl` for composing YAML manifests. [Docs](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)

## Repository Layout

```
./keda/                     # Kustomization for the full KEDA stack (with admission webhooks)
./keda-core/                # Kustomization for KEDA core components only
./keda-crds/                # Kustomization for CRDs only
./manifests/                # Shared demo manifests
./manifests/cpu-demo/       # CPU autoscaling Deployment + ScaledObject
./manifests/queue-demo/     # Redis + queue worker Deployment + ScaledObject
./scripts/                  # Helper automation scripts
./src/                      # .NET sample applications
./src/cpu-api/              # ASP.NET Core API that self-generates CPU load
./src/queue-worker/         # .NET worker that drains a Redis list slowly
./src/queue-producer/       # Console app that enqueues messages into Redis
DemoKeda.sln                # Solution tying the .NET projects together
patch-metrics-apiserver-hostnetwork.yaml  # Optional hostNetwork patch
```

The kustomizations reference the upstream release YAMLs shipped with KEDA v2.17.2.

## Installing Without the Helper Script

If you prefer raw `kubectl` commands, apply the kustomization that matches your needs:

```bash
# All-in-one (CRDs + operator + metrics-apiserver + admission webhooks)
kubectl apply --server-side -k ./keda

# Core-only (CRDs + operator + metrics-apiserver; no admission webhooks)
kubectl apply --server-side -k ./keda-core

# CRDs only (when you manage the controller separately)
kubectl apply --server-side -k ./keda-crds
```

Server-side apply keeps KEDA’s large CRDs from exceeding the Kubernetes annotation size limit. You can also consume the upstream YAML directly if you prefer:

```bash
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.17.2/keda-2.17.2.yaml
```

> **Tip:** Use `kubectl get deploy -n keda` after installing to verify the operator, metrics server, and admission deployment are all available.

## Optional: HostNetwork Patch

Some managed clusters require the metrics API server to run on the node network to reach the Kubernetes API server. Use `patch-metrics-apiserver-hostnetwork.yaml` with any kustomization:

```yaml
# Example: keda/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/kedacore/keda/releases/download/v2.17.2/keda-2.17.2.yaml
patches:
  - path: ../patch-metrics-apiserver-hostnetwork.yaml
    target:
      kind: Deployment
      name: keda-metrics-apiserver
      namespace: keda
```

If Domain Name System (DNS) resolution fails when enabling `hostNetwork`, switch the patch `dnsPolicy` to `ClusterFirstWithHostNet`.

## Verification Checklist

These read-only commands confirm KEDA is healthy:

```bash
kubectl get ns keda
kubectl get deploy -n keda
kubectl wait -n keda --for=condition=Available deploy/keda-operator --timeout=180s
kubectl wait -n keda --for=condition=Available deploy/keda-metrics-apiserver --timeout=180s
kubectl get crd | grep keda.sh
kubectl get apiservice v1beta1.external.metrics.k8s.io -o \
  jsonpath='{.status.conditions[?(@.type=="Available")].status}'
```

## KEDA Diagnostics Commands

Swap the placeholders (`<namespace>`, `<scaledobject-name>`, `<metric-name>`, `<deployment-name>`, etc.) for the resources in your cluster.

### Inspect ScaledObjects and HPAs

```bash
# List all ScaledObjects in a namespace
kubectl get scaledobjects -n <namespace>

# Describe a specific ScaledObject (status, triggers, conditions)
kubectl describe scaledobject <scaledobject-name> -n <namespace>

# List HPAs created by KEDA in the namespace
kubectl get hpa -n <namespace>

# Inspect an individual HPA for metrics and replica history
kubectl describe hpa <hpa-name> -n <namespace>
```

### Query External Metrics

```bash
# List external metrics exposed by KEDA
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1"

# Retrieve a specific metric for a ScaledObject in a namespace
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/<namespace>/<metric-name>?labelSelector=scaledobject.keda.sh%2Fname%3D<scaledobject-name>"

# If you use CPU or memory scalers (metrics.k8s.io API)
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
```

### Watch Scaling In Real Time

```bash
# Follow HPA target/current metrics and replica changes live
kubectl get hpa -n <namespace> -w

# Watch the backing Deployment scale
kubectl get deployment <deployment-name> -n <namespace> -w

# Observe pod-level metrics (requires metrics server)
kubectl top pods -n <namespace>
```

### Suggested Troubleshooting Flow

```bash
# 1. Confirm the ScaledObject exists and review the target resource
kubectl get scaledobject <scaledobject-name> -n <namespace> -o yaml

# 2. Check which external metrics the ScaledObject reports
kubectl get scaledobject <scaledobject-name> -n <namespace> -o jsonpath="{.status.externalMetricNames}"

# 3. Query one of those metric values directly
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/<namespace>/<metric-name>?labelSelector=scaledobject.keda.sh%2Fname%3D<scaledobject-name>"

# 4. Inspect the HPA generated by KEDA
kubectl describe hpa <hpa-name> -n <namespace>

# 5. Watch the deployment and pods for replica changes
kubectl get deployment <deployment-name> -n <namespace> -w
kubectl get pods -n <namespace> -w

# 6. Validate scale-to-zero (if expected)
kubectl get deployment <deployment-name> -n <namespace>
```

## Manual Smoke Test

You can reproduce the helper script’s smoke test manually if you want to see each step:

```bash
kubectl create ns keda-test
kubectl apply -f manifests/hello-deploy.yaml
kubectl apply -f manifests/hello-cron-scaledobject.yaml
kubectl get deploy -n keda-test -w
# ...
kubectl delete -f manifests/hello-cron-scaledobject.yaml
kubectl delete -f manifests/hello-deploy.yaml
kubectl delete ns keda-test
```

## Azure Functions Demo (Direct Commands) *(optional)*

> **Important:** The Azure Functions base image currently publishes AMD64 layers only. Use an x64 builder (or `docker buildx` / Podman with QEMU) and enable the helper commands with `ENABLE_FUNCTIONS_DEMO=1` after the image is available to your cluster.

```bash
ENABLE_FUNCTIONS_DEMO=1 ./scripts/keda-demo.sh deploy-functions-demo
ENABLE_FUNCTIONS_DEMO=1 ./scripts/keda-demo.sh functions-load 200 25  # requests, delay (ms)

kubectl get deploy -n keda-demo functions-runtime -w
kubectl logs -n keda-demo deploy/functions-runtime --tail=20

./scripts/keda-demo.sh remove-functions-demo
```

## Upgrades

Update the version strings in the kustomizations and re-apply:

```bash
# Example: bump to v2.17.3
sed -i.bak 's/v2.17.2/v2.17.3/g' keda/kustomization.yaml keda-core/kustomization.yaml keda-crds/kustomization.yaml
rm -f keda/*.bak keda-core/*.bak keda-crds/*.bak
kubectl apply --server-side -k ./keda        # or ./keda-core, ./keda-crds
```

## Uninstall

Safe to run even if some resources were already removed:

```bash
# All-in-one deployment
kubectl delete -k ./keda

# Core-only deployment
kubectl delete -k ./keda-core

# CRDs only (make sure no custom resources remain)
kubectl delete -k ./keda-crds
```
