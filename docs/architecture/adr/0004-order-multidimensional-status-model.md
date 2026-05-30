# ADR 0004: Order lifecycle — multi-dimensional status model

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

> Consolidates ADR candidate #14.

## Context and Problem Statement

A DistribuYa order moves through credit approval, fulfillment, and payment — but these progressions are **not** sequential. Under Net 30 terms an order can be `Delivered` and still `Not_Paid`. An order can be credit-`Approved` while fulfillment has not started. Modeling this as a single linear status forces false sequentiality and produces awkward reporting and automation. We need a status model that reflects the genuinely parallel nature of the B2B order lifecycle.

## Decision Drivers

- Credit, fulfillment, and payment progress independently and concurrently.
- Reporting must answer cross-cutting questions ("all delivered, unpaid orders").
- Each functional team (credit, operations, finance) should own its own dimension.
- Preserve native `Order` behavior (Draft/Activated) for standard features.
- Provide a single human-friendly stage for UI without collapsing the underlying truth.

## Considered Options

1. **Three orthogonal status picklists** (`Credit_Status__c`, `Fulfillment_Status__c`, `Payment_Status__c`) + a derived `Order_Stage__c` formula, leaving standard `Status` untouched.
2. **Single linear status picklist** enumerating every combined state.
3. **A separate status/transition custom object** (state-machine table).

## Decision Outcome

Chosen: **Option 1 — three orthogonal status fields + a derived stage formula**, because it represents the parallel reality directly, enables clean cross-dimension reporting, and assigns natural ownership per team while keeping the standard `Status` intact.

- `Status` (standard): untouched (Draft / Activated).
- `Credit_Status__c`: `Not_Required` / `Pending` / `Approved` / `Rejected`.
- `Fulfillment_Status__c`: `Not_Started` / `In_Picking` / `Shipped` / `Delivered` / `Cancelled`.
- `Payment_Status__c`: `Not_Paid` / `Partially_Paid` / `Paid`.
- `Order_Stage__c`: formula deriving a single user-facing label from the three dimensions.

## Pros and Cons of the Options

### Option 1 — Orthogonal status fields + formula (chosen)
- ✅ Models genuinely concurrent progressions without contradictions.
- ✅ Cross-cutting reports are trivial (filter by any combination).
- ✅ Clear domain ownership: credit team owns `Credit_Status__c`, ops owns `Fulfillment_Status__c`, finance owns `Payment_Status__c`.
- ✅ Keeps standard `Status` and its native behavior.
- ❌ The derived `Order_Stage__c` formula must encode the combination rules and be maintained.
- ❌ More fields to learn than a single status.

### Option 2 — Single linear status
- ✅ One field, simple at first glance.
- ❌ Combinatorial explosion of states (Delivered+Unpaid, Approved+InPicking+PartiallyPaid…).
- ❌ Forces false ordering; breaks reporting and ownership.

### Option 3 — Status/transition object
- ✅ Powerful for complex, audited state machines.
- ❌ Overkill here; adds querying/UX overhead for what three picklists express cleanly.

## Consequences

- The `Order_Stage__c` formula centralizes the combination logic; changes to UI stages happen there.
- Automation (Flow Orchestration for credit, ops processes, finance) updates its own dimension independently.
- Reports/list views are built on the orthogonal fields.
- Slightly higher field count and a non-trivial formula to maintain.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Each dimension's true state is explicit and independently auditable. |
| Easy to Change | Positive | UI representation lives in one formula; underlying states evolve independently. |
| Adaptable | Positive | New values per dimension (e.g. `Backordered`) add without restructuring. |
| Resilient | Neutral | No direct resilience impact. |
| Composable | Positive | Each team consumes/owns its own status dimension cleanly. |
