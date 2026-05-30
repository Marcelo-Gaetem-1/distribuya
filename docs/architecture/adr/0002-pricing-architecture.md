# ADR 0002: Pricing architecture (segment pricebooks, customer override, volume tiers)

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

> Consolidates ADR candidates #1, #7, #10, #11, #12. **This ADR resolves the previously-TBD link target of `Price_Tier__c`** (see Decision Outcome).

## Context and Problem Statement

DistribuYa prices the same catalog differently across three customer segments (Retailer, Restaurant, Small Business), negotiates one-off prices with individual customers, and grants volume discounts by quantity. We need a pricing model that handles all three mechanisms, defines a deterministic precedence when they overlap, stays on standard pricing objects where possible, and remains future-proof given that Salesforce CPQ is in End-of-Sale.

## Decision Drivers

- Segment-based list pricing must be native and auditable by the catalog team.
- Per-customer negotiated prices must be time-bounded and traceable to who negotiated them.
- Volume discounts must scale to an arbitrary number of quantity breaks.
- A single, deterministic precedence order when override + tier + base all apply.
- Avoid re-implementing Pricebook/Order/OrderItem (80/20 rule).
- Future-proof: CPQ is End-of-Sale (2024–2025); Revenue Cloud Advanced is the strategic successor.

## Considered Options

1. **3 segment `Pricebook2` + `Customer_Price__c` (override) + `Price_Tier__c` (volume tiers)** with an Apex `PricingService` cascade.
2. **Single `Pricebook2`** with discounts expressed as fields/picklists on Order/OrderItem.
3. **One `Pricebook2` per customer**.
4. **Adopt Salesforce CPQ / Revenue Cloud Advanced now**.

## Decision Outcome

Chosen: **Option 1**, because it uses standard Pricebooks for segment list pricing, isolates negotiated and volume pricing into purpose-built custom objects, and centralizes precedence in one Apex service — without the weight of a full CPQ adoption in Phase 1.

- **Segment pricing**: 3 × `Pricebook2` ("Retailer", "Restaurant", "Small Business"). `Order.Pricebook2Id` is set from `Account.Segment__c`; new customers without a segment default to "Small Business".
- **Customer override**: `Customer_Price__c` (`Account__c`, `Product2__c`, `Override_Price__c`, `Effective_Date__c`, `End_Date__c`, `Negotiated_By__c`, `Notes__c`).
- **Volume tiers**: `Price_Tier__c` (`Min_Quantity__c`, `Max_Quantity__c` nullable for the top tier, `Tier_Price__c`, effective dates).
- **`Price_Tier__c` link target (resolves the TBD)**: **Lookup to `PricebookEntry`**, making tiers **segment-aware** (each segment Pricebook can define its own tiers), consistent with the segmented architecture. The alternative (Lookup to `Product2`, i.e. global tiers) is documented below and can supersede this if the business wants segment-independent tiers.
- **Precedence (Apex `PricingService`, Phase 2)**: `customer override → applicable volume tier by quantity → base segment Pricebook entry`.
- **v2 roadmap**: migration path to Revenue Cloud Advanced documented; CPQ explicitly avoided.

## Pros and Cons of the Options

### Option 1 — Segment Pricebooks + Customer_Price__c + Price_Tier__c (chosen)
- ✅ Segment list pricing is fully native and admin-maintainable.
- ✅ Overrides and tiers are time-bounded, auditable, and scale to any number of breaks.
- ✅ Single cascade in one service = one place to reason about precedence.
- ✅ No CPQ licensing or End-of-Sale exposure.
- ❌ Pricing resolution requires custom Apex (`PricingService`) rather than out-of-the-box behavior.
- ❌ Two custom objects to govern.

### Option 2 — Single Pricebook + discount fields
- ✅ Minimal objects.
- ❌ Cannot express segment list prices cleanly; discounts become scattered field logic.
- ❌ Volume breaks hardcoded into a fixed number of fields — does not scale.

### Option 3 — Pricebook per customer
- ✅ Conceptually simple per-customer pricing.
- ❌ Explodes Pricebook count and maintenance; unmanageable at hundreds/thousands of customers.

### Option 4 — CPQ / Revenue Cloud now
- ✅ Rich, declarative pricing engine.
- ❌ CPQ is End-of-Sale; Revenue Cloud Advanced is heavy for Phase 1 and not available in Developer Edition. Premature.

## Consequences

- An Apex `PricingService` (Phase 2) becomes the single source of pricing truth; it must be well-tested for the override/tier/base cascade.
- `OrderItem` records the applied price source (`Applied_Price_Source__c`) and the modifier id (`Price_Modifier_Id__c`) for audit — see ERD.
- Choosing segment-aware tiers means tier records reference `PricebookEntry`; a future switch to global tiers would be a data-migration-bearing change (hence documented as the alternative).
- The Revenue Cloud Advanced migration path is recorded for v2.
- Platform limits: tier/override lookups must be selective to avoid SOQL inefficiency at scale — addressed in the service-layer design.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Time-bounded overrides with `Negotiated_By__c` and per-line applied-price source give a full pricing audit trail. |
| Easy to Change | Positive | Segment prices and tiers are data, editable by admins/catalog team without code changes. |
| Adaptable | Positive | Tiers scale to any number of quantity breaks; segment Pricebooks extend to new segments. |
| Resilient | Neutral | Pricing is transactional/synchronous; no specific resilience concern beyond standard governor limits. |
| Composable | Positive | A single `PricingService` exposes one pricing contract reusable by Orders, the portal, and integrations. |
