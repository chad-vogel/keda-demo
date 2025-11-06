# Slide 12 – Case Study Example

<p>
  <a href="https://learn.microsoft.com/azure/azure-functions/"><img src="../assets/logos/azure-functions.png" alt="Azure Functions logo" width="130" /></a>
  <a href="https://keda.sh/"><img src="../assets/logos/keda-logo.svg" alt="KEDA logo" width="130" /></a>
</p>

## Talking Points

- Define a Kubernetes Event-Driven Autoscaling (KEDA) `ScaledObject` that points at the containerised Azure Functions deployment.
- Deploy both the container image and the `ScaledObject` manifest into the cluster.
- Push events into the trigger source and watch pods scale automatically.
- Mirrors the behaviour of Azure Functions Consumption Plan while running entirely on your Kubernetes cluster.

## Example Manifest

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: functions-runtime
  namespace: apps
spec:
  scaleTargetRef:
    name: functions-runtime
  pollingInterval: 15
  cooldownPeriod: 60
  minReplicaCount: 0
  maxReplicaCount: 20
  triggers:
    - type: cpu
      metadata:
        type: Utilization
        value: "60"
```

*How to use it:* Apply the manifest alongside the deployment for your Azure Functions runtime container. Generate load—such as queue messages or HTTP requests—and KEDA will scale the pods based on the configured trigger.

## Exercise

1. Edit the manifest above to point at the namespace and deployment name used in your environment.
2. Apply it with `kubectl apply -f scaledobject.yaml`.
3. Run a load generator (`./scripts/keda-demo.sh functions-load 200 25`) and monitor scaling with `kubectl get hpa -A`.
4. Adjust the `value` and `pollingInterval` fields to see how quickly scaling reacts.

## Related Documentation

- [Architecture & flow – CPU autoscaling demo](../architecture.md#cpu-autoscaling-demo) – companion explanation for the manifest fields shown here.
- [Reference & manual operations – manual smoke test](../reference.md#manual-smoke-test) – step-by-step guidance for applying manifests directly with `kubectl`.

## Navigation

<p>
  <a href="slide-11.md">← Back</a>
  <span style="float:right;"><a href="slide-13.md">Next →</a></span>
</p>
