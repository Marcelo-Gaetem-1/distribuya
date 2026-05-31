# Phase 2 — Core Automation: Discovery & Plan

> **Goal of Phase 2**: bring the Phase 1 data model to life with automation — pricing resolution, credit-approval orchestration, order lifecycle, and stock-reservation timeout — built on Flow + Apex + Platform Events.
>
> **Status**: Planning (no code yet). This mirrors the Phase 1 discovery approach: decide order, trade-offs, and ADR candidates first.
>
> **Mentor note**: decisions below are proposals with trade-offs; the apprentice (Marcelo) confirms before we build.

## 1. What Phase 2 must deliver (from Phase 1 ADRs)

| Capability | Source ADR | Mechanism (decided in Phase 1) |
|---|---|---|
| Price resolution (override → tier → base) | ADR-0002 | Apex `PricingService` |
| Credit approval (tiered, multi-step) | ADR-0005 | Flow Orchestration + `Credit_Approval_Tier__mdt` |
| Order lifecycle transitions | ADR-0004 | Record-triggered flows on the 3 status fields |
| Stock reservation + timeout | ADR-0006 | Reservation on order; Time-Triggered Path expiry |
| Credit history capture | ADR-0003 | Auto-write `Credit_History__c` on credit-field change |
| Branch ownership inheritance | ADR-0007 | Trigger/flow: Branch Account owner = parent's owner |
| Decoupled eventing / integration seam | — | Platform Events (prepares Phase 4) |

## 2. Proposed build order (dependency-driven)

1. **PricingService (Apex)** — pure, testable logic; everything else can call it. No external deps. *Start here.*
2. **Credit auto-history + branch ownership** — small record-triggered flows/triggers; immediate WAF "Trusted" value, low risk.
3. **Stock reservation + Time-Triggered Path timeout** — depends on order creation existing.
4. **Credit approval Flow Orchestration** — the richest piece; depends on the tier CMDT (manual values pending) + PricingService for exposure calc.
5. **Order lifecycle flows** — tie credit/fulfillment/payment statuses together; depends on 3 & 4.
6. **Platform Events** — introduce once there's something to publish (order approved, stock consumed); bridges to Phase 4.

Rationale: start with the dependency-free, highly-testable core (PricingService), then layer record automation, then orchestration. Each step is independently deployable and demoable.

## 3. Key decisions to make (Phase 2 ADR candidates)

| # | Decision | Options | Lean |
|---|---|---|---|
| P2-1 | Trigger framework | Raw triggers vs handler pattern vs Apex-trigger-actions vs Flow-only | Handler pattern (one trigger per object + handler class) — testable, standard |
| P2-2 | Where pricing is invoked | OrderItem trigger vs LWC/screen action vs both | Service called from both; trigger as backstop for data integrity |
| P2-3 | PricingService design | Single method vs strategy per source | Single entry `resolvePrice(accountId, product, qty, date)` returning price + source + modifierId |
| P2-4 | Credit exposure calculation | Real-time aggregate query vs maintained `Credit_Used__c` rollup | Apex aggregate at approval time (accuracy over caching) — revisit if volume demands |
| P2-5 | Reservation availability | Runtime `Available - SUM(active)` vs maintained rollup | Runtime in PricingService-style ReservationService; defer rollup (YAGNI) |
| P2-6 | Test data strategy | `@TestSetup` factories vs inline | Central `TestDataFactory` for Accounts/Products/Pricebooks/Orders |
| P2-7 | Bulkification baseline | — | All Apex bulk-safe + selective SOQL from day one (non-negotiable for Architect portfolio) |

## 4. WAF lens for Phase 2

- **Easy to Change**: logic in services + handlers, not scattered; config (tiers) stays in CMDT.
- **Resilient**: bulk-safe Apex, governor-aware; Platform Events decouple integration so ERP outages don't block order-taking.
- **Trusted**: credit history auto-captured; approvals audited via Orchestration runs.
- **Composable**: `PricingService` / `ReservationService` reusable by triggers, LWC, portal, and integration.

## 5. Out of scope for Phase 2

- Experience Cloud UI (Phase 3), real ERP/logistics/payment endpoints (Phase 4 — mocked), AI (Phase 5).

## 6. Open prerequisites before coding

- ⏳ 3 `Credit_Approval_Tier__mdt` record values (manual, tracked in `manual-deploy/`) — needed for the approval orchestration (step 4), **not** for PricingService (step 1), so we can start coding without it.
