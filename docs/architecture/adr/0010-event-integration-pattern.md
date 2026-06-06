# ADR 0010: Outbound event integration pattern — Flow vs Apex vs Hybrid

## Status

Accepted — 2026-06-06 (Phase 4)

> Reached by applying the standard → declarative → Apex ladder (ADR-0008) *with evidence*, including a governor-limit/performance analysis prompted by the apprentice's questions. This ADR documents why Apex is justified here — not assumed.

## Context and Problem Statement

When an Order is credit-approved, DistribuYa publishes `Order_Approved__e` (Phase 2). Phase 4 must consume that event and **confirm the order to the ERP** with a **resilient** pattern: retry with backoff, dead-letter after N failures, and full audit (`Integration_Log__c`) — per ADR-0006 and the Phase-4 discovery (P4-3, P4-6). How should the subscriber + callout be built?

## Considered Options (ladder applied)

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

Chosen: **Option B — Apex (subscriber + Queueable)**, because the requirement is *resilient* integration (retry + dead-letter + audit), and **resilience is not available declaratively** (verified: no native DLQ, finite retries, Flow can't configure batch size). This passes all four "go-custom" tests: complex logic, reused pattern, needs unit-tested control of retries, and no declarative option fits.

**Key evidence that drove this (not assumed):**
1. The OpenAPI schema *can* be self-authored — so the declarative callout is technically possible (the apprentice was right to challenge the earlier "schema is a blocker" claim). The callout is **not** why we choose Apex.
2. We choose Apex because **retry + dead-letter + batch-size control** are the requirement, and only Apex provides them coherently.
3. The **hybrid is worse**, not better — two contexts, mixed limits, inconsistent attribution.

## Consequences

- Build: `OrderApprovedSubscriber` (PE trigger) → `ErpOrderConfirmationQueueable` (callout, mocked in Dev Edition) → `IntegrationLogger` (writes `Integration_Log__c`) → retry/backoff + dead-letter.
- Dev Edition has no real ERP → **HttpCalloutMock** in tests + a stub endpoint; the *patterns* are real and demonstrable, the endpoint is simulated.
- If a future requirement is a *simple* fire-and-forget notification, Option A (Flow + External Services) is the right tool — documented here so the choice is reusable.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Every call audited in `Integration_Log__c`; dead-letter prevents silent loss. |
| Easy to Change | Neutral | More code than Flow, but isolated in a service + queueable. |
| Adaptable | Positive | Named Credential swaps mock↔real ERP without code change. |
| Resilient | Positive | Retry + backoff + dead-letter — the whole point. |
| Composable | Positive | Logger + queueable reusable by logistics/payments integrations. |

## Sources
- [Connecting to an API with Flow HTTP Callout (Salesforce Help)](https://help.salesforce.com/s/articleView?id=platform.flow_http_callout.htm&type=5)
- [External Services + OpenAPI (Salesforce Help)](https://help.salesforce.com/s/articleView?id=platform.external_services_examples_openapi_3_0.htm&type=5)
- [Platform Events subscribe considerations — callouts, batch size (Developer Guide)](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm)
