# Slide 09 – Example Architecture

<p>
  <a href="https://learn.microsoft.com/azure/azure-functions/"><img src="../assets/logos/azure-functions.png" alt="Azure Functions logo" width="120" /></a>
  <a href="https://keda.sh/"><img src="../assets/logos/keda-logo.svg" alt="KEDA logo" width="120" /></a>
  <a href="https://kubernetes.io/"><img src="../assets/logos/kubernetes-logo.png" alt="Kubernetes logo" width="120" /></a>
</p>

## Talking Points

- Events push into a queue or event source where KEDA listens for activity.
- The KEDA scaler exposes metrics to the Kubernetes metrics API, translating backlog into desired replica counts.
- The Horizontal Pod Autoscaler (HPA) adjusts the Azure Functions deployment to meet demand.
- Monitor the feedback loop for bottlenecks such as queue throughput, cold starts, or resource quotas.

## Flow Diagram

```mermaid
flowchart LR
    EventSource["Event source (queue, stream, or schedule)"]
    KedaScaler["KEDA scaler + metrics adapter"]
    MetricsAPI["Kubernetes metrics Application Programming Interface (API)"]
    HPA["Horizontal Pod Autoscaler (HPA)"]
    FunctionPods["Azure Functions runtime pods"]

    EventSource --> KedaScaler --> MetricsAPI --> HPA --> FunctionPods
```

*Diagram:* Event sources feed KEDA, which publishes external metrics for the HPA. The HPA scales the function pods to keep pace with demand.

## Hands-On Exercise

- Deploy the queue demo from this repository (`./scripts/keda-demo.sh deploy-queue-demo`).
- Run `./scripts/keda-demo.sh enqueue 200` to create a backlog and follow `kubectl get deploy -n keda-demo queue-worker -w` to watch live scaling.
- Compare the observed behaviour with the flow diagram and identify where metrics are exposed.

## Related Documentation

- [Architecture & flow – Redis queue autoscaling demo](../architecture.md#redis-queue-autoscaling-demo) – detailed explanation of the components referenced in this exercise.

## Demo Assets

- Worker code: [`src/queue-worker/`](../src/queue-worker)
- Producer code: [`src/queue-producer/`](../src/queue-producer)
- Kubernetes manifests: [`manifests/queue-demo/`](../manifests/queue-demo)
- Automation commands: `./scripts/keda-demo.sh deploy-queue-demo`, `./scripts/keda-demo.sh enqueue`, `./scripts/keda-demo.sh queue-depth`

## Scenario Snapshot

- **Trigger** – a major tour announcement drives a sudden spike in ticket purchases. Queue depth jumps from zero to thousands within seconds.  
- **Response** – KEDA monitors the queue backlog, signalling the HPA to scale processing pods from one replica to dozens within half a minute.  
- **Recovery** – once the backlog drains, KEDA gradually scales back to a minimal footprint, conserving infrastructure spend.

## Navigation

<p>
  <a href="slide-08.md">← Back</a>
  <span style="float:right;"><a href="slide-10.md">Next →</a></span>
</p>
