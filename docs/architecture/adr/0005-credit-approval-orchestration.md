# ADR 0005: Credit approval orchestration (Flow Orchestration + Custom Metadata matrix)

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

> Consolidates ADR candidates #2, #15, #16.

## Context and Problem Statement

Orders that push a customer's exposure beyond their credit limit require a tiered, multi-step, multi-user approval: a commercial level, a manager level, and a credit-team level depending on how far the limit is exceeded. The mechanism must compute exposure, route to the right approver dynamically, keep an audit trail, and let the approval tiers be reconfigured by admins without code changes. We must choose the orchestration mechanism and where the tier matrix lives.

## Decision Drivers

- Multi-step, multi-user process with automated and interactive stages.
- Dynamic approver assignment based on the exceeded ratio.
- Strong, native audit trail.
- Approval tiers must be admin-configurable and versioned with metadata, not buried in code.
- Use modern, strategically-invested platform capabilities.

## Considered Options

1. **Flow Orchestration** for the process + **Custom Metadata Type `Credit_Approval_Tier__mdt`** for the tier matrix.
2. **Approval Process (classic)** with the matrix in code or step config.
3. **Pure Apex** approval engine.
4. **Chained Record-Triggered Flows** without Orchestration.

## Decision Outcome

Chosen: **Option 1 — Flow Orchestration + `Credit_Approval_Tier__mdt`**, because Orchestration is purpose-built for multi-step/multi-user processes with native audit, and Custom Metadata is the correct primitive for infrequently-changing, admin-maintainable, deployable configuration.

- **Mechanism**: Flow Orchestration (a standard Flow type as of Spring '26, with no usage caps / licensing barrier).
- **Stages**: Pre-Approval Analysis (auto) → Approval Decision (interactive) → Apply Decision (auto).
- **Tier matrix**: `Credit_Approval_Tier__mdt` with `Min_Ratio__c`, `Max_Ratio__c` (nullable for the top tier), `Approver_Role__c`. Initial tiers: 0–100% (Sales Rep), 100–150% (Manager), 150%+ (Credit Team).
- A background step reads the matrix and computes exposure/tier; the resulting approver is stored in an orchestration variable and used as the interactive step assignee.
- `Order.Credit_Status__c` is updated by background steps as stages progress; the Orchestration Run history provides the audit trail.

## Pros and Cons of the Options

### Option 1 — Flow Orchestration + Custom Metadata (chosen)
- ✅ Designed for exactly this multi-stage, multi-actor pattern.
- ✅ Native Orchestration Run audit history.
- ✅ Tiers are deployable config (CMDT) — admin-editable, versioned, environment-portable.
- ✅ Standard Flow type in Spring '26 — no licensing barrier; signals modern platform awareness.
- ❌ Newer tooling with a learning curve.
- ❌ Orchestration debugging is less mature than plain Flows.

### Option 2 — Approval Process (classic)
- ✅ Familiar, battle-tested.
- ❌ Limited native dynamic assignment; weaker audit and modern tooling; not where Salesforce invests.

### Option 3 — Pure Apex engine
- ✅ Total control.
- ❌ Re-implements orchestration/audit by hand; higher maintenance; less admin-friendly.

### Option 4 — Chained Record-Triggered Flows
- ✅ All declarative.
- ❌ No first-class multi-user stage/audit construct; orchestration state becomes ad-hoc and fragile.

## Consequences

- The approval process is built as a Flow Orchestration; admins reconfigure tiers by editing `Credit_Approval_Tier__mdt` (no deployment of code).
- Approver roles in the matrix must align with the role hierarchy (sharing-model ADR).
- Orchestration Run records become the approval audit source.
- Team must build Flow Orchestration skills; debugging tooling maturity is a watch-item.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Native run history + deployable tier config give auditable, governed approvals. |
| Easy to Change | Positive | Tier thresholds and approvers change as metadata, not code. |
| Adaptable | Positive | Stages and tiers extend (new levels, extra analysis steps) without re-architecting. |
| Resilient | Neutral | Synchronous approval process; relies on platform orchestration runtime. |
| Composable | Positive | Orchestration and the tier matrix are reusable building blocks for other approval flows. |
