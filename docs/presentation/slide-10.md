# Slide 10 – Trade-offs and Pitfalls

## Talking Points

- **Cold start latency** – scaling from zero introduces startup delay; budget for this in user-facing scenarios.
- **Operational complexity** – running Kubernetes (K8s), Kubernetes Event-Driven Autoscaling (KEDA), and the function runtime adds moving parts to own.
- **Scaling ceilings and misconfiguration** – ensure queue throughput, concurrency limits, and KEDA settings align.
- **Cost overheads** – weigh the platform investment against fully managed serverless offerings.
- **Feature divergence** – track differences between Azure Consumption Plan features and your Kubernetes implementation.

## Mitigation Ideas

- Use readiness and liveness probes to detect unhealthy pods quickly and recycle them before errors propagate.
- Pre-warm a small baseline of pods during peak hours if cold start latency is unacceptable.
- Document a decision matrix comparing managed serverless versus self-hosted KEDA for different workload profiles.

## Related Documentation

- [Reference & manual operations – verification checklist](../reference.md#verification-checklist) – commands for confirming that readiness and Horizontal Pod Autoscaler (HPA) health signals are working.

## Navigation

<p>
  <a href="slide-09.md">← Back</a>
  <span style="float:right;"><a href="slide-11.md">Next →</a></span>
</p>
