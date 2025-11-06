# Slide 11 – Best Practices

## Talking Points

- Provide standardised container templates for function apps so teams start with secure, observable defaults.
- Abstract Kubernetes Event-Driven Autoscaling (KEDA) complexity behind shared tooling or internal platforms to reduce configuration drift.
- Define realistic scaling policies: minimum and maximum replicas, cooldown periods, and queue thresholds.
- Monitor cold starts explicitly and invest in readiness probes or warm queues where latency matters.
- Enforce resource quotas and budgets to prevent noisy neighbours from overwhelming the cluster.
- Explore predictive or scheduled scaling to complement purely reactive triggers.
- Automate security baseline tasks such as secret management, network policies, and certificate rotation.

## Helpful Resources

- [Kubernetes Policy Templates with Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/) – enforce guardrails for scaled workloads.
- [Azure Functions Best Practices](https://learn.microsoft.com/azure/azure-functions/functions-best-practices)

## Related Documentation

- [Demo overview – teardown](../overview.md#teardown) – shows how to clean environments safely after experimenting with these best practices.

## Navigation

<p>
  <a href="slide-10.md">← Back</a>
  <span style="float:right;"><a href="slide-12.md">Next →</a></span>
</p>
