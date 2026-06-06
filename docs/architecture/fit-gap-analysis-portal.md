# Fit-Gap Analysis — B2B Portal: Salesforce B2B Commerce vs Custom (Experience Cloud + LWC)

> **What this is**: the build-vs-buy analysis an Architect produces *before* committing to a portal implementation. It maps each DistribuYa portal requirement to what **B2B Commerce (standard)** delivers vs what a **custom LWC build** requires, then recommends a path. This is the discovery step we initially skipped (see ADR-0009) — done properly here.
>
> **Author's note**: this document is the deliverable; the recommendation it reaches drives the build. Written 2026-06-05.

## 1. Context

DistribuYa is a **B2B wholesale distributor** selling to retailers/restaurants/shops. The portal must let customers browse a catalog, see *their* pricing, and place orders — with per-customer/segment pricing, volume discounts, multi-branch accounts, and credit-limit approval. This is a textbook B2B commerce profile.

Two options are technically available in the org (B2B Commerce was enabled 2026-06-05; objects `WebStore`, `WebCart`, `BuyerGroup`, `CommerceEntitlementPolicy` confirmed present):
- **Option A — B2B Commerce (standard)**: purpose-built storefront product.
- **Option B — Custom (Experience Cloud LWR + LWC + Apex)**: the POC already built in Phase 3.

## 2. Requirement-by-requirement fit-gap

Legend: ✅ OOTB (config) · 🟡 OOTB + some config/code · 🔴 fully custom build · ⚪ not needed

| # | Requirement | B2B Commerce (standard) | Custom (LWC) | Notes |
|---|---|---|---|---|
| R1 | Authenticated B2B login | ✅ Buyer users + store | 🟡 Community Plus + custom | Both work; Commerce buyer model is purpose-built. |
| R2 | Browse catalog (families → products, categories) | ✅ Catalog + Category objects | 🔴 `CatalogController` + LWC | Commerce: config. Custom: we hand-built it. |
| R3 | **Per-segment / per-customer pricing** | ✅ **Buyer Groups + Entitlement Policies + custom Price Books** | 🔴 `PricingService` Apex cascade | Commerce models this *natively* via Buyer Group → Price Book. We built it in Apex. |
| R4 | **Volume / tier pricing** | ✅ Tiered pricing in price books | 🔴 `Price_Tier__c` + Apex | Commerce supports quantity tiers OOTB. |
| R5 | Cart + checkout | ✅ WebCart/CartItem + checkout flow | 🔴 `cartSummary` LWC + `PortalOrderController` | Commerce: full cart/checkout engine. Custom: we built a minimal cart (and hit the LWC↔Apex serialization saga, LL-027). |
| R6 | **Multi-branch accounts** (parent + branches) | ✅ Account Groups / multi-account buyer | 🟡 ACR Sharing Sets (partial) | Commerce has native multi-account buyer support. Custom needs sharing-set tuning (gap U3). |
| R7 | Place order → becomes an `Order` | ✅ Checkout creates Order | ✅ `PortalOrderController` | Both land in the standard Order object. |
| R8 | **Credit-limit approval** on over-limit orders | 🟡 Commerce + our Phase-2 flow/approval | 🟡 Phase-2 flow/approval | *Neither* product does DistribuYa's specific tiered credit matrix OOTB — our Phase-2 automation (CreditExposureService + Approval Process) is the differentiator either way. |
| R9 | Order history for the buyer | ✅ My Account / order history OOTB | 🔴 not built (gap U7) | Commerce gives this free; custom = build a new LWC. |
| R10 | Hide internal data (credit, stock) from buyers | ✅ Entitlements + sharing | ✅ Portal PS + sharing sets | Both handle it; we hardened the custom path (USER_MODE/SYSTEM_MODE). |
| R11 | Promotions / coupons (future) | ✅ OOTB | 🔴 full build | Not a current requirement, but Commerce has it for free. |
| R12 | Self-service reorder (distributor staple) | ✅ Reorder from history OOTB | 🔴 full build | Core B2B distributor behavior; Commerce native. |

## 3. Scorecard

| Dimension | B2B Commerce | Custom LWC |
|---|---|---|
| Coverage of requirements OOTB | **~9/12 config** | ~3/12 (rest hand-built) |
| Time to a robust, all-cases portal | **Lower** (config + learning curve) | Higher (build every gap U1–U7) |
| Maintenance burden | **Lower** (Salesforce maintains the engine) | Higher (we own all the code + bugs) |
| Flexibility for truly unique logic | Medium (opinionated model) | **High** |
| Fit for a *wholesale distributor* | **Excellent** (its target use case) | Adequate |
| Demonstrates dev skill (portfolio) | Low (mostly config) | High (but author didn't author the code) |

## 4. The decisive factors

1. **DistribuYa IS the textbook B2B Commerce use case** — a wholesale distributor with per-customer pricing, tiers, multi-branch, reorder. The official guidance explicitly targets "distributors and manufacturers."
2. **B2B Commerce delivers R3/R4/R6/R9/R12 natively** — exactly the gaps (U1, U3, U4, U7) the custom POC left open. Buying solves them; building means weeks of work.
3. **The Phase 1 data model + Phase 2 automation stay valuable regardless** — credit approval (CreditExposureService, Approval Process), platform events, and the audit model are the *real* differentiators and sit *behind* either front end. We don't throw those away.
4. **Portfolio goal = demonstrate Architect judgment, not hand-written code** — the most valuable artifact is *this analysis* plus implementing the *correct* decision on the standard product.

## 5. Recommendation

**Adopt B2B Commerce for the storefront** (catalog, pricing via Buyer Groups + Entitlement Policies, cart, checkout, order history, reorder), **keeping the Phase 1 data model and Phase 2 automation** (credit approval, pricing matrix as a fallback/validation, platform events) as the business logic and system of record behind it.

**Retire the custom LWC portal to "evaluated POC" status** — it remains in the repo as the proof-of-concept that informed this decision, and as a record of the build-vs-buy reasoning. It is *not* deleted (it has documentary value), but it is not the path forward.

### Why not keep custom?
Sunk cost (the POC time) does not justify building R3/R4/R6/R9/R12 by hand when the product does them natively for our exact use case. An Architect optimizes for total cost of ownership, not for preserving already-written code.

### Why not pure B2B Commerce with nothing custom?
DistribuYa's **tiered credit-approval matrix** (CreditExposureService + Approval Process + Credit_Approval_Tier__mdt) is genuinely custom — no commerce product does that specific logic OOTB. That stays as our Phase-2 differentiator, invoked from the commerce order flow.

## 6. Implementation plan (POC, staged & verified)

1. **Create a B2B Store** (WebStore) bound to the DistribuYa data.
2. **Catalog + Categories** — map Product2 / families / categories into the store catalog.
3. **Buyer Group + Entitlement Policy + Price Book** — model the 3 segments (Retailer/Restaurant/Small Business) as buyer-group-scoped price books (replaces our 3-Pricebook + PricingService approach with the standard mechanism).
4. **Buyer account + test buyer user** — Don Mario / a branch.
5. **Checkout flow** — standard, creating an Order.
6. **Wire the Phase-2 credit approval** to the commerce order (the one piece that stays custom).
7. **Verify each step before the next** (lesson from the LL-027 saga).

## 7. WAF alignment of the recommendation

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Entitlement policies + standard security are battle-tested. |
| Easy to Change | Positive | Config over code; Salesforce maintains the engine. |
| Adaptable | Positive | Promotions, reorder, etc. available without new builds. |
| Resilient | Positive | Less custom code = fewer custom failure modes (cf. LL-027). |
| Composable | Positive | Phase-2 services (credit, events) plug into the commerce flow. |

## Sources
- [Buyer Groups, Entitlements, and Pricing (Salesforce Help)](https://help.salesforce.com/s/articleView?id=commerce.comm_buyergroup_entitlements_pricebooks.htm&language=en_US&type=5)
- [Entitlement Policies for B2B Stores](https://help.salesforce.com/s/articleView?id=commerce.comm_entitlement_policies_intro.htm&language=en_US&type=5)
- [Enable Buyer Entitlements with Account Groups](https://help.salesforce.com/s/articleView?id=sf.b2b_commerce_account_group.htm&language=en_US&type=5)
- ADR-0009 (portal build approach) in this repo.
