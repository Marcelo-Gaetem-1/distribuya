# ADR 0008: Automation tool selection — the standard → declarative → Apex ladder

## Status

Accepted — 2026-05-31 (Phase 2)

## Context and Problem Statement

Phase 2 introduces behavior (automation). On the Salesforce platform the same outcome can often be achieved by a **standard feature**, by **declarative tooling (Flow)**, or by **Apex code**. Choosing wrongly hurts maintainability ("Easy to Change") or testability/composability. We need an explicit, repeatable rule for *which tool* implements each automation, and a record of how it was applied to the first Phase 2 builds.

## Decision Drivers

- WAF **Easy to Change**: prefer the lowest-code option a future admin can maintain.
- WAF **Trusted / Resilient**: complex or bulk-critical logic needs tests and predictability.
- Architect-interview defensibility: every "we used Apex" must have a reason beyond preference.
- The apprentice is still learning Apex — declarative should not be skipped by default.

## Decision Outcome

Adopt the **automation ladder**, evaluated in order for every new automation:

1. **Standard feature** — does an out-of-the-box capability already do this? Use it.
2. **Declarative (Flow / validation rules / formulas)** — if no standard feature, can a Flow do it maintainably? Use it.
3. **Apex** — only when declarative can't, or when the logic is complex, highly reusable, or must be unit-tested as a service.

**Apex is justified when** the logic is (a) complex/algorithmic, (b) reused across entry points (trigger + LWC + integration), (c) requires bulk guarantees with versioned unit tests, or (d) no declarative option fits.

### How it applied to the first Phase 2 builds

| Build | Standard? | Flow possible? | Chosen | Justification |
|---|---|---|---|---|
| PricingService | no | partially (complex cascade) | **Apex** | Complex override→tier→base logic, reused by triggers/LWC/portal/integration, needs bulk + unit tests. Clear Apex case. |
| Reservation timeout | no | **yes** (Time-Triggered Path) | **Flow** | Declarative fits; near-exact per-record expiry. ADR-0006. |
| Credit auto-history | no | **yes** | **Apex** (already built) | *Honest note:* Flow could do this. Built in Apex for unit-test coverage + portfolio demonstration of the trigger-handler pattern. **Borderline** — kept because it is built, tested (12/12), and reusable; not because Flow couldn't. |
| Branch ownership | no | **yes** | **Apex** (already built) | Same as above. Borderline; kept for consistency with the Account trigger handler. |

## Consequences

- From this ADR onward, **the ladder is applied explicitly and the apprentice decides** when a build is "borderline" (declarative vs Apex), rather than defaulting to Apex.
- The two borderline Account automations stay in Apex (`AccountTriggerHandler`) — reversing them would discard tested, working code for little gain. Documented here so the choice is defensible, not silent.
- New automations get a one-line ladder check in their commit/PR ("standard? flow? why Apex?").

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Apex paths carry unit tests; declarative paths use platform-tested runtime. |
| Easy to Change | Positive | Ladder biases toward the most maintainable option; admins can own Flows. |
| Adaptable | Neutral | Tool choice is per-build; ladder scales to new requirements. |
| Resilient | Positive | Bulk-critical logic lands in tested Apex; timers in platform-managed Scheduled Paths. |
| Composable | Positive | Service-layer Apex (PricingService) is reusable; Flows stay single-purpose. |
