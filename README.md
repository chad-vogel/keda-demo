# KEDA Demo (November 2025)

This repository bundles the official Kubernetes Event-Driven Autoscaling (KEDA) v2.17.2 manifests and a set of .NET workloads so you can install, verify, and demo event-driven autoscaling with nothing more than `kubectl`. The helper script automates the common flows, and the documentation explains every step with links to background reading.

### Why This Demo Avoids Helm

Helm is a powerful packaging tool, but for this demo the manifests are applied directly with `kubectl`. Coming from a security-focused operations background, I have repeatedly seen richly-templated Helm charts obscure configuration changes, introduce default permissions that teams do not realize they are granting, and complicate day-two maintenance when clusters are audited. Applying the upstream manifests directly keeps the configuration transparent, minimises moving parts, and makes it easier to review exactly what is being installed. If your organisation standardises on Helm, you can absolutely deploy KEDA that way—the section below links to the official chart—this repo simply demonstrates the “plain YAML + kubectl” path for clarity and maintainability.

Resources for Helm-based installs:
- [Helm](https://helm.sh/) – package manager for Kubernetes
- [KEDA Helm charts](https://github.com/kedacore/charts) – official charts maintained by the KEDA project

## Documentation

- [Demo overview](docs/overview.md) – prerequisites, quickstart, image builds, and workload walkthroughs.
- [Environment setup](docs/setup.md) – create a local cluster with Podman + kind (and alternatives).
- [Architecture & flow](docs/architecture.md) – diagrams that show how KEDA, HPAs, and the sample apps interact.
- [Reference & manual operations](docs/reference.md) – repo layout, manual install/uninstall, verification, and upgrade notes.
- Presentation materials:
  - [PowerPoint deck (.pptx)](docs/Serverless_on_Kubernetes_Azure_Functions_KEDA.pptx)
  - [Per-slide Markdown notes](docs/presentation/README.md)

## Key Scripts

- `scripts/keda-demo.sh` – installs KEDA, deploys the smoke/CPU/queue demos, drives load jobs, and reports status.
- `scripts/keda-demo-tear-down.sh` – idempotent cleanup for the demos and KEDA stack (optionally deletes the kind cluster).

## Quick Peek

```bash
./scripts/keda-demo.sh install-all
./scripts/keda-demo.sh wait
./scripts/keda-demo.sh status
./scripts/keda-demo.sh smoke-test
```

Run through the rest of the scenarios in the [demo overview](docs/overview.md), then clean up with `./scripts/keda-demo-tear-down.sh --delete-kind-cluster`.

Additional demo commands:
- `./scripts/keda-demo.sh deploy-cpu-demo`, `./scripts/keda-demo.sh cpu-load 180 6`
- `./scripts/keda-demo.sh deploy-queue-demo`, `./scripts/keda-demo.sh enqueue 200`
- Azure Functions sample (optional, requires `ENABLE_FUNCTIONS_DEMO=1` and an AMD64-capable image builder): `./scripts/keda-demo.sh deploy-functions-demo`, `./scripts/keda-demo.sh functions-load 400 25`

## Testing

```bash
dotnet test
```

The solution includes xUnit tests with FluentAssertions and Moq. Install the .NET 8 runtime (or enable roll-forward) to execute them locally.

## Vue 3 Dashboard Example

A companion dashboard (TypeScript + Vue 3) lives under `web/keda-dashboard/`. It polls a demo API that exposes Kubernetes workloads and KEDA metrics.

```
cd web/keda-dashboard
npm install
npm run dev
```

Set `VITE_KEDA_DEMO_API` to the base URL of a lightweight API proxy or port-forwarded service that surfaces the workloads in your cluster.

## Further Reading

- [How to migrate Durable Functions to KEDA](https://learn.microsoft.com/answers/questions/1841889/how-to-migrate-durable-function-to-keda)

## Repo Structure

The top-level layout mirrors the documentation:

```
docs/                     # Markdown + slide deck documentation
manifests/                # Demo workloads (CPU, queue, cron)
keda*/                    # Upstream release kustomizations
scripts/                  # Helper automation
src/                      # Sample .NET applications
```

Everything else in the repo is pulled into the new docs, so start there for deeper dives.
