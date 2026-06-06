# ADR 0010: Outbound event integration pattern — Outbound Messages vs Flow vs Apex

## Status

**REVISED 2026-06-06** → chosen option changed from **Apex** to **Outbound Messages (standard)**.

> **Honesty correction**: the first version of this ADR compared only Flow-callout vs Apex vs Hybrid and concluded "Apex (it has retry/dead-letter, declarative doesn't)." That analysis **missed a standard option entirely: Outbound Messages**, which provide retry + exponential backoff + a delivery-failure (dead-letter) report **natively, zero code**. The apprentice's question "did we evaluate a standard way?" surfaced the gap. The ladder (ADR-0008) is now applied *completely*. This is itself the lesson: we almost reinvented in Apex a resilience mechanism Salesforce ships standard.

## Context and Problem Statement

When an Order is credit-approved, DistribuYa publishes `Order_Approved__e` (Phase 2). Phase 4 must consume that event and **confirm the order to the ERP** with a **resilient** pattern: retry with backoff, dead-letter after N failures, and full audit (`Integration_Log__c`) — per ADR-0006 and the Phase-4 discovery (P4-3, P4-6). How should the subscriber + callout be built?

## Considered Options (ladder applied — corrected)

### Option 0 — STANDARD: Outbound Messages (the one we initially missed)
- A **Workflow/Flow → Outbound Message** sends a SOAP/XML notification to the ERP endpoint when the trigger fires.
- ✅ **Native retry with exponential backoff** (15 sec → 60 min, for 24h; extensible to 7 days via Support).
- ✅ **Native dead-letter**: failures land in the *Outbound Message Delivery Failure* report for inspection/manual replay.
- ✅ **Zero code**, fully declarative.
- ❌ **SOAP/XML only** (not REST/JSON) — payload is the record's fields, no transformation/enrichment.
- ❌ Tied to a specific notification shape; not for complex multi-step orchestration.
- **Verdict**: for "reliably notify the ERP that an order was approved," this delivers the exact resilience (retry + dead-letter) we were about to hand-build in Apex. **This is the standard answer.**

### Option A — Declarative: External Services + Flow subscriber
- The ERP REST API can be described with an **OpenAPI schema we author ourselves** (Swagger Editor), registered via **External Services** + a **Named Credential**, exposing the ERP operation as an invocable action.
- **A Flow Platform-Event subscriber CAN make the callout directly** (verified — Flow PE triggers allow callouts; Apex PE triggers do not, synchronously).
- Logging via a Fault Path creating an `Integration_Log__c`.
- ✅ No code for the callout. ❌ **No native retry / no dead-letter** (Salesforce has no built-in DLQ; finite retries). ⚠️ Flow PE triggers **can't configure batch size** (fixed at 2000) → governor-limit risk under event bursts. ⚠️ DML attributed to the initiating user.

### Option B — Apex: subscriber + Queueable callout
- Apex PE subscriber → enqueues a **Queueable** that makes the callout (Apex PE triggers can't call out synchronously, so Queueable is the *recommended* pattern, not a workaround).
- Full **retry with exponential backoff + dead-letter** in code; logs to `Integration_Log__c`.
- ✅ One coherent context; **configurable batch size** (lower to stay within limits); full control of payload/retry. ❌ More code.

### Option C — Hybrid: Flow callout + Apex retry
- Flow does the callout, Apex handles retry/dead-letter.
- ❌ **Rejected.** Two execution contexts for one flow = two sets of governor limits to coordinate, inconsistent DML attribution (Flow=initiating user, Apex=Automated Process), and higher maintenance/debug cost. The apprentice flagged the limit/performance risk — confirmed: it combines the downsides of both with no clear upside.

## Decision Outcome

**Chosen: Option 0 — Outbound Messages (standard)** for the ERP order-confirmation notification, because the requirement (resilient outbound notification: retry + backoff + dead-letter + audit) is **delivered natively, no code** — which is exactly what the ladder demands (use standard before declarative before custom).

**Why this overrides the earlier "Apex" conclusion:**
1. The earlier analysis was incomplete — it never evaluated Outbound Messages, so it wrongly concluded "resilience needs Apex." Outbound Messages provide retry/backoff/dead-letter standard.
2. Building a Queueable + retry-counter + dead-letter in Apex would **reinvent a native capability** — the exact anti-pattern the standard-first ladder exists to prevent.
3. The audit requirement (`Integration_Log__c`) is still satisfiable: a Flow can write the log alongside, and the Outbound Message Delivery Failure report covers failure visibility.

**When Apex WOULD still be justified (documented, not chosen now):**
- ERP requires **REST/JSON** (Outbound Messages are SOAP/XML only) → then Flow HTTP Callout (declarative) or Apex callout, per complexity.
- Payload needs **enrichment/transformation/multi-record aggregation** beyond the record's own fields.
- Multi-step orchestration across systems.

For the portfolio POC, the architecturally correct demonstration is: **show the standard mechanism (Outbound Message) as the primary answer, and document the Apex/Flow-callout path as the REST/transformation alternative.**

## Consequences

- **Primary (standard)**: configure a Flow (on `Order_Approved__e` or Order credit-approval) → **Outbound Message** to the ERP endpoint. Native retry/backoff/dead-letter. Optionally a Flow step writes `Integration_Log__c` for unified audit.
- **`IntegrationLogger` (already built) is NOT wasted**: it remains the audit/dead-letter backbone for the integrations that *do* need Apex (e.g. REST inbound stock sync, payments), and can be called from Flow via an invocable wrapper.
- **Apex subscriber + Queueable: NOT built** (would reinvent standard). If/when a REST-based ERP is the requirement, revisit with Flow HTTP Callout first.
- Dev Edition: the Outbound Message endpoint is a mock/RequestBin-style URL; the delivery + retry behavior is real and demonstrable.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Every call audited in `Integration_Log__c`; dead-letter prevents silent loss. |
| Easy to Change | Neutral | More code than Flow, but isolated in a service + queueable. |
| Adaptable | Positive | Named Credential swaps mock↔real ERP without code change. |
| Resilient | Positive | Native retry + backoff + dead-letter report — standard, no custom code to maintain. |
| Composable | Positive | IntegrationLogger reusable for the Apex-justified integrations (REST inbound sync, payments). |

## Sources
- [Outbound Messages — retry/backoff behavior (Salesforce Help)](https://help.salesforce.com/s/articleView?id=platform.workflow_managing_outbound_messages.htm&type=5)
- [Outbound Message vs Platform Event — Architect guide (SalesforceCodex)](https://salesforcecodex.com/salesforce/salesforce-outbound-message-vs-platform-event-a-complete-architects-guide/)
- [Connecting to an API with Flow HTTP Callout (Salesforce Help)](https://help.salesforce.com/s/articleView?id=platform.flow_http_callout.htm&type=5)
- [Platform Events subscribe considerations — callouts, batch size (Developer Guide)](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm)
