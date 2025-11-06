# Slide 08 – Engineering Considerations

## Talking Points

- **Trigger characteristics and latency** – understand how quickly each trigger surfaces events to the scaler.
- **Cold start behaviour** – measure startup time for new pods and mitigate with warm pools or pre-loading.
- **ScaledObject and ScaledJob Custom Resource Definitions (CRDs)** – configuration surface for KEDA triggers and batch jobs.
- **Authentication and workload identity** – secure connections to event sources, secrets, and managed identities.
- **Horizontal Pod Autoscaler (HPA) interplay** – ensure resource requests and limits support the desired scaling profile.
- **Multi-tenant isolation** – design namespaces, queues, and identities to avoid cross-team interference.
- **Observability and monitoring** – capture queue depth, scale decisions, and pod health for feedback loops.

## Deep-Dive Resources

- [Designing Distributed Systems: Patterns for Event Sources](https://learn.microsoft.com/azure/architecture/patterns)
- [Azure Active Directory Workload Identity for Kubernetes](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [KEDA Scaling Behaviour Tuning](https://keda.sh/docs/latest/concepts/scaling-deployments/)

## Related Documentation

- [Environment setup](../setup.md) – explains how to configure Podman and kind before experimenting with the identity and scaling topics discussed here.

## Navigation

<p>
  <a href="slide-07.md">← Back</a>
  <span style="float:right;"><a href="slide-09.md">Next →</a></span>
</p>
