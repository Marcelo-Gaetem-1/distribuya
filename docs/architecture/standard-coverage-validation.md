# Standard Coverage Validation — Does B2B Commerce cover DistribuYa, or is custom justified?

> The rigorous check an Architect runs before closing the build-vs-buy decision: map **every original DistribuYa requirement** (from the charter) to what B2B Commerce delivers standard, and identify any gap that *legitimately* requires custom — per the "4 legitimate reasons to go custom" (ADR pattern / standard-vs-custom.md).
>
> **Date**: 2026-06-06. Answers the question: "did we validate that standard covers everything, or is something genuinely custom?"

## The 6 charter requirements vs B2B Commerce standard

| # | Charter requirement | B2B Commerce standard? | Verdict |
|---|---|---|---|
| C1 | **Catálogo con precios por cliente** (catalog + per-customer pricing) | ✅ Catalog, Categories, Buyer Groups, Entitlement Policies, Price Books | **Standard covers it.** Validated in POC (catalog + Small Business pricebook reused). |
| C2 | **Pedidos online** (online ordering) | ✅ Cart, checkout, Order creation | **Standard covers it.** (Checkout needs a payment adapter — config, not custom logic.) |
| C3 | **Aprobaciones por límite de crédito** (credit-limit approval) | 🔴 **NOT standard** | **Custom is JUSTIFIED.** See below — this is the genuine differentiator. |
| C4 | **Integración con ERP / logística / pagos** | 🟡 Commerce has connectors/payment framework; ERP/logistics = integration build | **Mixed** — Phase 4 work, custom integration regardless of front end. |
| C5 | **Portal self-service** | ✅ B2B Commerce storefront (OOTB) | **Standard covers it.** The custom LWC portal was the POC; Commerce is the answer. |
| C6 | **Forecasting de demanda** (demand forecasting) | 🟡 Not commerce; needs Data Cloud / analytics | **Phase 5** — separate (AI layer), neither commerce nor custom-portal concern. |

## The one place custom is genuinely justified: C3 (credit approval)

Run it through the **4 legitimate reasons to go custom** (from `docs/patterns/standard-vs-custom.md`):

1. **Standard semantics don't fit?** ✅ Yes. B2B Commerce has no concept of a *tiered credit-exposure approval matrix* (0–100% → Sales Rep, 100–150% → Manager, 150%+ → Credit Team) driven by `(Credit_Used + order) / Credit_Limit`, reading a deployable CMDT matrix, with parent-account credit for branches.
2. **Standard fields insufficient?** ✅ Yes — needs `Credit_Approval_Tier__mdt`, `CreditExposureService`, the approval orchestration.
3. **Limits/behavior block the use case?** ✅ Commerce checkout doesn't gate on a custom credit ratio.
4. **Specialized domain pattern?** ✅ Tiered credit approval is a distributor/banking-style pattern, not a commerce primitive.

**4 of 4 reasons hold → custom is defensible.** This is the DistribuYa differentiator and it **stays custom, behind whichever front end is used** (Commerce or otherwise). It is exactly what an Architect keeps custom while buying the commodity storefront.

## What about the Phase-1 custom objects we now know are superseded?

These were modeled custom in Phase 1 but B2B Commerce provides standard equivalents (so custom was **not** justified for them — the process miss recorded in ADR-0009):

| Phase-1 custom | Standard equivalent | Custom justified? |
|---|---|---|
| `Product_Category__c` | `ProductCategory` | ❌ No — standard covers it (validated in POC). |
| `Product_Family__c` | Native Product2 variations | ❌ No — standard covers variants. |
| `Customer_Price__c` | Buyer Group + Entitlement + Price Book | ❌ No — standard pricing covers it. |
| `Price_Tier__c` | Native tiered pricing | ❌ No — standard covers tiers. |

> These remain in the repo as the (over-)custom Phase-1 model. In a real adoption of B2B Commerce they would be retired in favor of the standard objects. Kept here for the documentary/learning record.

## Answer to "did we validate standard covers everything?"

**Yes — validated, requirement by requirement:**
- **4 of 6 charter requirements (C1, C2, C5, and the catalog/pricing core)** → **fully covered by B2B Commerce standard.** No custom justified; POC proved it live.
- **1 requirement (C3 credit approval)** → **genuinely needs custom**, passes all 4 "go-custom" tests. This is the one thing we correctly keep custom.
- **2 requirements (C4 integrations, C6 forecasting)** → out of scope for the storefront decision (Phase 4 / Phase 5).

**Conclusion**: the standard product covers the commerce requirements; the only justified custom is the **credit-approval automation (Phase 2)**, which we already built and which plugs in behind the standard storefront. Nothing else needs custom — and the 4 Phase-1 catalog/pricing customs are confirmed redundant.

This is the complete build-vs-buy validation. **No remaining requirement is silently relying on un-validated custom.**
