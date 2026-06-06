# ADR 0009: Portal build approach — B2B Commerce vs custom LWC on Experience Cloud

## Status

**Revised 2026-06-05 by the [Fit-Gap Analysis](../fit-gap-analysis-portal.md).** After enabling B2B Commerce in the org and running a formal fit-gap, the conclusion changed to **adopt B2B Commerce for the storefront** (keep Phase-1 data model + Phase-2 automation behind it; retire custom LWC to "evaluated POC"). The original reasoning below is kept for the record.

Original status: Accepted (retroactively documented) — 2026-06-05 (Phase 3)

> **Honesty note**: this ADR was written *after* building the portal with custom LWC. The decision was originally made implicitly (P3-1 in the Phase 3 discovery just said "LWR + LWC") **without evaluating the standard product**. The Fit-Gap corrects that omission with a proper requirement-by-requirement build-vs-buy, per the ADR-0008 ladder (standard → declarative → custom).

## Context and Problem Statement

DistribuYa needs a B2B self-service portal: customers browse a catalog, see their pricing, and place orders. Salesforce offers a **purpose-built product for exactly this** — **B2B Commerce** — as well as the option to build a **custom portal on Experience Cloud (LWR) with hand-written LWC + Apex**. We must choose, and be able to defend the choice.

## Decision Drivers

- The **standard-first principle** (ADR-0008): is there an out-of-the-box product before we build?
- Project goal: this is a **portfolio** to demonstrate Salesforce Architect-level skill, not a production rollout.
- Maintainability, time-to-value, and what each option signals to a hiring manager.
- Functional fit: complex B2B buying (per-customer pricing, multi-branch, credit approval).

## Considered Options

1. **Salesforce B2B Commerce** — purpose-built storefront (catalog, cart, checkout, pricing OOTB).
2. **Custom LWC on Experience Cloud (LWR)** — hand-built catalog/cart/order components + Apex.
3. Hybrid (B2B Commerce + custom extensions).

## Decision Outcome

Chosen: **Option 2 — custom LWC on Experience Cloud**, **for the portfolio context**, while explicitly acknowledging that **Option 1 (B2B Commerce) is what a real DistribuYa rollout should use.**

Rationale:
- **For a real distributor**: B2B Commerce is the right answer. The official guidance is explicit — it "simplifies complex buying cycles, drives repeat orders" for distributors/manufacturers, with cart/catalog/checkout/pricing prebuilt. Building those by hand would violate the 80/20 rule.
- **For this portfolio**: custom LWC demonstrates Apex service design, LWC, FLS/sharing enforcement (USER_MODE/SYSTEM_MODE), and integration with the Phase 2 automation — skills a hiring manager wants to *see built*, not just configured. That demonstration value is the reason to keep custom here.

**The defensible interview answer**: "For production I'd use B2B Commerce — it's purpose-built. I built the portal custom in this portfolio to demonstrate the underlying platform skills (Apex services, LWC, security modes, sharing). I can articulate when each is appropriate."

## Consequences

- We own the cart/catalog/order code (and its bugs — see the LWC→Apex serialization saga, LL-027). B2B Commerce would have avoided that class of plumbing entirely.
- Several B2B features we'd get free from B2B Commerce are now our backlog: order history, robust multi-branch, promotions, entitlements (see technical-debt.md).
- The custom components remain reusable and are a concrete code sample.

## What a real DistribuYa should do (not-now, but recorded)

Adopt **B2B Commerce** (or Agentforce Commerce, the 2026 evolution) for the storefront, keep the Phase 1 data model + Phase 2 automation (credit approval, pricing service, platform events) as the system of record and business logic behind it.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Neutral | Both options can be secured; we hardened the custom path (USER_MODE gate). |
| Easy to Change | Negative (vs B2B Commerce) | Custom code is more to maintain than configured commerce. |
| Adaptable | Mixed | Custom = max flexibility but more effort; B2B Commerce = fast but opinionated. |
| Resilient | Neutral | — |
| Composable | Positive | Custom LWC + Apex services are reusable building blocks. |

## Sources

- [B2B Commerce vs Experience Cloud for a B2B portal (Brimit)](https://www.brimit.com/blog/building-a-b2b-customer-portal-experience-or-commerce-cloud)
- [Why Salesforce B2B Commerce (Spyrosoft)](https://spyro-soft.com/blog/salesforce/why-should-you-use-salesforce-b2b-commerce-cloud-and-how-to-start)
- [LWC↔Apex wrapper passing patterns (SalesforceCodex)](https://salesforcecodex.com/salesforce/sending-wrapper-object-to-apex-from-lwc/)
