# Slide 07 – Core Architectural Patterns

## Talking Points

- **Scale to zero** – reclaim resources when no events are flowing, without sacrificing rapid scale-out.
- **Event-driven triggers** – tie scaling behaviour to external signals rather than internal polling.
- **Separation of concerns** – platform teams manage KEDA triggers, while application teams focus on business logic.
- **Portability and flexibility** – run the same container images in managed cloud or on-premises clusters.
- **Platform enablement** – provide shared tooling, metrics, and guardrails so teams adopt event-driven patterns consistently.

## Practical Tips

- Create templates for `ScaledObject` definitions so teams do not need to memorise metadata options.
- Use namespace conventions (for example, `team-app-environment`) to keep scaled workloads isolated and auditable.
- Document fallback behaviour—what happens if the external trigger endpoint is unavailable—to prevent silent failures.

## Related Documentation

- [Reference & manual operations – repository layout](../reference.md#repository-layout) – shows where the example `ScaledObject` templates live within this project.

## Navigation

<p>
  <a href="slide-06.md">← Back</a>
  <span style="float:right;"><a href="slide-08.md">Next →</a></span>
</p>
