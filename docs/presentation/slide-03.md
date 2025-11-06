# Slide 03 – Why This Matters

## Talking Points

- Digital products are increasingly *event-driven*, reacting to orders, notifications, and scheduled workloads.
- Serverless platforms deliver *pay-per-use scaling*, aligning infrastructure cost with real demand.
- Kubernetes Event-Driven Autoscaling (KEDA) lets existing clusters adopt the same scale-from-zero behaviour without abandoning familiar tooling.
- Platform enablement avoids application-specific hacks—teams share consistent pipelines, metrics, and operations practices.

## Example Scenario

- A ticketing platform opens sales for a popular concert. Thousands of fans queue within seconds, creating a sudden backlog of payment requests.  
  - Without automation the cluster is either overprovisioned (wasting spend) or overwhelmed (failing orders).  
  - With KEDA, queue depth drives Kubernetes scaling: pods grow from 1 to dozens in seconds, then shrink back to zero overnight.

## Discussion Starters

- Which workloads in your organisation already react to events but still rely on manual scaling or cron jobs?
- What guardrails (security, latency, compliance) do you need before running these workloads inside your own cluster?

## Further Reading

- [Event-Driven Architecture Basics](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/event-driven)
- [Serverless Computing Economics](https://azure.microsoft.com/resources/whitepapers/serverless-economics/)

## Related Documentation

- [Architecture & flow](../architecture.md) – illustrates how queues, metrics, and Horizontal Pod Autoscalers (HPAs) connect inside this repository’s demo.

## Navigation

<p>
  <a href="slide-02.md">← Back</a>
  <span style="float:right;"><a href="slide-04.md">Next →</a></span>
</p>
