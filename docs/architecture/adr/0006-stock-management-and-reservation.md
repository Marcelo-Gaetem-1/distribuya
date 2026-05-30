# ADR 0006: Stock management and reservation (hybrid ERP model, reservation object, timeout)

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

> Consolidates ADR candidates #3, #17, #18, #19.

## Context and Problem Statement

Physical inventory lives in the ERP, the system of record for stock. DistribuYa, however, must temporarily reserve stock when an order is being placed/approved, expire reservations that go stale (2–4 hour window), and show "available to promise" without hammering the ERP on every check. We must decide (a) where stock truth lives and how Salesforce represents it, (b) how reservations are modeled, and (c) how reservation timeout is enforced.

## Decision Drivers

- Single source of truth for physical stock (ERP) without coupling every reservation check to ERP latency/availability.
- Reservations are a Salesforce-side commercial concern, independent of ERP.
- Reservations must outlive their order line for auditability.
- Near-exact, per-reservation expiry timing.
- Resilience: order-taking should keep working during ERP outages.

## Considered Options

**(a) Stock truth model**
1. **Hybrid** — ERP owns physical stock, synced to `Product2.Available_Stock__c`; Salesforce owns reservations.
2. **Salesforce as source of truth** for stock.
3. **Real-time ERP check** on every availability/reservation.

**(b) Reservation relationship to `OrderItem`**
1. **Lookup** (loose coupling, survives deletion).
2. **Master-Detail** (tight coupling, cascade delete).

**(c) Timeout mechanism**
1. **Time-Triggered Path** in a Record-Triggered Flow on `Stock_Reservation__c`.
2. **Centralized Scheduled Apex** sweep.

## Decision Outcome

Chosen: **(a) Hybrid**, **(b) Lookup**, **(c) Time-Triggered Path**.

- **`Stock_Reservation__c`** custom object, one reservation per `OrderItem`, fields: `Product2__c`, `OrderItem__c` (Lookup), `Quantity__c`, `Status__c` (`Active` → `Consumed`/`Released`/`Expired`), `Expiry_Timestamp__c`, `Reservation_Reason__c`, `Released_By__c`, `Released_Reason__c`.
- **Stock representation**: `Product2.Available_Stock__c` (synced from ERP), `Stock_Last_Sync__c`, `ERP_Product_ID__c` (unique external id). Available-to-promise = `Available_Stock__c − SUM(active reservations)`, computed at runtime (rollup-vs-runtime detail deferred to Phase 2 service layer).
- **Timeout**: a Time-Triggered Path fires off `Expiry_Timestamp__c`; if the reservation is still `Active`, it is set to `Expired`. A Scheduled Apex sweep is noted as an enterprise safety net but deferred (YAGNI).
- **ERP confirmation** of consumed stock is an outbound integration in Phase 4.

## Pros and Cons of the Options

### (a) Hybrid (chosen) vs alternatives
- ✅ Clear ownership: ERP = physical truth, Salesforce = commercial reservations.
- ✅ Avoids ERP latency on every check; order-taking survives ERP outages (resilience).
- ❌ Sync introduces eventual consistency on `Available_Stock__c`.
- ❌ (SF-as-truth) would duplicate ERP responsibility and risk divergence. ❌ (Real-time ERP check) couples UX to ERP uptime/latency.

### (b) Lookup (chosen) vs Master-Detail
- ✅ Reservation records survive `OrderItem` deletion → preserved audit trail (consistent with `Credit_History__c`).
- ✅ Terminal-state reporting (`Expired`/`Released`/`Consumed`) measures approval delays, rejections, conversions.
- ❌ Orphan handling on `OrderItem` deletion needs a small Record-Triggered Flow (accepted).
- ❌ (Master-Detail) cascade-deletes history — unacceptable for audit.

### (c) Time-Triggered Path (chosen) vs Scheduled Apex
- ✅ Near-exact (minute-level) per-reservation expiry; each record schedules its own.
- ✅ Declarative; signals modern Flow capability awareness.
- ❌ Many scheduled paths at very high volume need monitoring.
- ❌ (Scheduled Apex) coarser (~15-min) granularity; kept only as a backup sweep.

## Consequences

- A periodic inbound sync populates `Available_Stock__c`/`Stock_Last_Sync__c` from the ERP (Phase 4).
- `Stock_Reservation__c` is Private (OWD) and shared to Operations for active reservations (sharing-model ADR).
- A Record-Triggered Flow handles `OrderItem`-deletion orphans.
- Available-to-promise calculation (runtime aggregate vs maintained rollup) is finalized in the Phase 2 Apex service layer.
- Scheduled Apex safety-net remains an explicit, deferred option.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Reservations are auditable with terminal states and survive line deletion. |
| Easy to Change | Positive | Reservation rules/timeout live in declarative Flow; expiry window is data-driven. |
| Adaptable | Positive | Reservation object and sync extend to new fulfillment rules without ERP changes. |
| Resilient | Positive | Order-taking continues during ERP outages; hybrid model decouples uptime. |
| Composable | Positive | Clear domain boundary (ERP vs SF) and a reusable reservation concept. |
