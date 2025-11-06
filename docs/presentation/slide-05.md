# Slide 05 – KEDA Overview

<p>
  <a href="https://keda.sh/"><img src="../assets/logos/keda-logo.svg" alt="KEDA logo" width="160" /></a>
</p>

## Talking Points

- Kubernetes Event-Driven Autoscaling (KEDA) augments native Kubernetes scaling with external triggers.
- KEDA works alongside the Horizontal Pod Autoscaler (HPA), allowing workloads to scale down to zero or up to meet demand.
- Core components: the KEDA operator, metrics adapter, and pluggable scalers for dozens of event sources.
- KEDA gives platform teams a uniform scaling story across queues, databases, cloud services, and custom metrics.

## Key Concepts

- **ScaledObject** – custom resource that links a deployment to a trigger definition.
- **ScaledJob** – custom resource that schedules batch jobs based on event metrics rather than cron schedules.
- **External scaler** – gRPC extension point that lets you integrate bespoke data sources when a built-in scaler is unavailable.

## Further Reading

- [Built-in KEDA Scalers](https://keda.sh/docs/latest/scalers/)
- [External Scalers Specification](https://keda.sh/docs/latest/concepts/external-scalers/)
- [Migrating Durable Functions to KEDA](https://learn.microsoft.com/answers/questions/1841889/how-to-migrate-durable-function-to-keda)

## Related Documentation

- [Reference & manual operations – installing without the helper script](../reference.md#installing-without-the-helper-script) – shows how the repository applies Kubernetes Event-Driven Autoscaling (KEDA) manifests directly.

## Demo Assets

- CPU autoscaling sample: [`src/cpu-api/`](../src/cpu-api), manifests [`manifests/cpu-demo/`](../manifests/cpu-demo)
- Queue autoscaling sample: [`src/queue-worker/`](../src/queue-worker), manifests [`manifests/queue-demo/`](../manifests/queue-demo)
- Automation: `./scripts/keda-demo.sh deploy-cpu-demo`, `./scripts/keda-demo.sh cpu-load`, `./scripts/keda-demo.sh deploy-queue-demo`, `./scripts/keda-demo.sh enqueue`
- Optional Vue dashboard: [`web/keda-dashboard/`](../web/keda-dashboard) (TypeScript + Vue 3)

## Step-by-Step (CPU & Queue)

1. `./scripts/keda-demo.sh deploy-cpu-demo`
2. `./scripts/keda-demo.sh cpu-load 180 6`
3. `kubectl get hpa -n keda-demo`
4. `./scripts/keda-demo.sh remove-cpu-demo`
5. `./scripts/keda-demo.sh deploy-queue-demo`
6. `./scripts/keda-demo.sh enqueue 200 backlog 100`
7. `kubectl get deploy -n keda-demo queue-worker -w`
8. `./scripts/keda-demo.sh remove-queue-demo`

## Navigation

<p>
  <a href="slide-04.md">← Back</a>
  <span style="float:right;"><a href="slide-06.md">Next →</a></span>
</p>
