# Slide 01 – Serverless on Kubernetes: Azure Functions + KEDA Deep Dive

## Talking Points

- Introduce the session: *Serverless on Kubernetes: Azure Functions + Kubernetes Event-Driven Autoscaling (KEDA) Deep Dive*.
- Presenter: Chad Vogel (Tech Talk).
- Position the session as a practical walkthrough for application engineers exploring serverless patterns on Kubernetes.

<p>
  <a href="https://learn.microsoft.com/azure/azure-functions/"><img src="../assets/logos/azure-functions.png" alt="Azure Functions logo" width="140" /></a>
  <a href="https://keda.sh/"><img src="../assets/logos/keda-logo.svg" alt="KEDA logo" width="140" /></a>
  <a href="https://kubernetes.io/"><img src="../assets/logos/kubernetes-logo.png" alt="Kubernetes logo" width="140" /></a>
</p>

## Key Concepts

- **Serverless computing** – a cloud execution model where infrastructure provisioning and scaling are managed automatically. You focus on code and events rather than servers.
- **Azure Functions** – Microsoft’s Function-as-a-Service runtime that reacts to events such as Hypertext Transfer Protocol (HTTP) requests, timers, and queue messages.
- **Kubernetes Event-Driven Autoscaling (KEDA)** – an open-source project that lets Kubernetes scale workloads based on external event streams and scale them all the way to zero when idle.

## Why It Matters

- Many organisations already standardise on Kubernetes for container workloads. KEDA bridges the gap between existing cluster tooling and serverless expectations such as pay-per-use scaling.
- Understanding these primitives empowers application engineers to collaborate more effectively with platform teams and to design workloads that scale predictably.

## Further Reading

- [What is Serverless? (Microsoft Learn)](https://learn.microsoft.com/azure/architecture/serverless-quickstart)
- [KEDA Concepts Overview](https://keda.sh/docs/latest/concepts/)
- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)

## Related Documentation

- [Demo overview](../overview.md) – repository-specific quickstart, prerequisites, and workload walkthroughs.
- [Architecture & flow](../architecture.md) – diagrams showing how Kubernetes Event-Driven Autoscaling (KEDA) interacts with the sample workloads.

## Navigation

<p align="right">
  <a href="slide-02.md">Next →</a>
</p>
