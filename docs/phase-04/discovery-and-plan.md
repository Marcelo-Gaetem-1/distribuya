# Phase 4 — Integrations: Discovery & Plan

> **Goal**: connect DistribuYa to the external systems a wholesale distributor depends on — **ERP** (stock + product master + order confirmation), **logistics** (shipment), **payments** — with resilient, retryable, auditable integration patterns.
>
> **Status**: Planning (no build yet). Mirrors prior phases' discovery approach.
>
> **Foundation already in place** (from Phase 1/2): `Order_Approved__e` platform event (the outbound seam), `Product2.ERP_Product_ID__c` (external id for idempotent upsert), `Stock_Last_Sync__c`, the hybrid stock model (ADR-0006). Phase 4 builds on these.

## 1. What Phase 4 must deliver (from the charter + ADRs)

| Integration | Direction | Trigger / cadence | Source ADR |
|---|---|---|---|
| **ERP — stock sync** | inbound | scheduled / batch | ADR-0006 (ERP = source of truth, synced to `Available_Stock__c`) |
| **ERP — product master** | inbound | scheduled | ADR-0006 (`ERP_Product_ID__c` external id) |
| **ERP — order confirmation** | outbound | on `Order_Approved__e` | Phase 2 (event published on credit approval) |
| **Logistics — shipment** | outbound | post-fulfillment | charter C4 |
| **Payments** | outbound/inbound | at order / on settlement | charter C4 + B2B Commerce (if adopted) |

## 2. Key architecture decisions (Phase 4 ADR candidates)

| # | Decision | Options | Lean |
|---|---|---|---|
| P4-1 | Integration style | Point-to-point Apex callouts vs Platform Events + middleware vs External Services/MuleSoft | **Platform Events for outbound** (already publishing `Order_Approved__e`) + Apex callouts behind subscribers; document MuleSoft as enterprise option |
| P4-2 | Inbound stock sync | Scheduled Apex batch vs Platform Event from ERP vs Change Data Capture | Scheduled Apex (Dev-Edition-friendly) + upsert by `ERP_Product_ID__c` |
| P4-3 | Resilience: retry + dead-letter | Custom retry table vs Platform Event replay vs queueable retries | Queueable + a `Integration_Log__c` dead-letter (retry + audit) |
| P4-4 | Idempotency | Upsert by external id everywhere | Non-negotiable — `ERP_Product_ID__c` upsert, order external ref |
| P4-5 | Mocking external systems (Dev Edition) | Named Credentials to a mock endpoint vs Apex stub vs static responses | Apex mock + a mock REST endpoint; real endpoints documented |
| P4-6 | Error visibility | `Integration_Log__c` custom object | Yes — every callout logs request/response/status for audit (Trusted pillar) |

## 3. Proposed build order

1. **`Integration_Log__c`** + a logging service (the audit/dead-letter backbone — everything else writes to it).
2. **Outbound: ERP order confirmation** — a subscriber to `Order_Approved__e` that does a (mocked) callout, logs result, retries on failure. *Reuses the seam we already built.*
3. **Inbound: ERP stock sync** — Scheduled Apex that upserts `Product2.Available_Stock__c` by `ERP_Product_ID__c`, stamps `Stock_Last_Sync__c`.
4. **Logistics shipment** — outbound on fulfillment status change.
5. **Payments** — outbound at order, inbound settlement updates `Order.Payment_Status__c`.
6. **Named Credentials + mock endpoints** — so callouts are real-shaped but hit a stub in Dev Edition.

## 4. WAF lens

- **Resilient**: retry + dead-letter (`Integration_Log__c`); Platform Events decouple so an ERP outage doesn't block order-taking (already a Phase-2/ADR-0006 principle).
- **Trusted**: every integration call audited; idempotent upserts prevent duplicates.
- **Composable**: each integration is an independent subscriber/job; ERP, logistics, payments don't know about each other.
- **Adaptable**: Named Credentials swap mock↔real without code change.

## 5. Constraints / honest notes

- **Dev Edition has no real ERP/gateway** — Phase 4 uses **mocks** (Apex stubs + a mock REST endpoint). The patterns (retry, dead-letter, idempotency, logging) are real and demonstrable; the endpoints are simulated. This is the right scope for a portfolio.
- **If B2B Commerce is adopted** (Phase 3 decision): Commerce has its own payment framework and order model — payments integration would route through Commerce. The ERP/logistics integrations are independent of the storefront and unaffected.
- Callout governor limits + async patterns (Queueable/Batch) must be respected — bulk-safe from day one.

## 6. First concrete step

Build **`Integration_Log__c`** (object + fields: direction, system, status, request, response, error, related record, retry count) + an `IntegrationLogger` Apex service. It is dependency-free and underpins every other integration. Then the `Order_Approved__e` subscriber.
