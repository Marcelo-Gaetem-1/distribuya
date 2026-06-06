# Phase 3 — B2B Commerce POC: Result & Conclusion

> Outcome of the staged B2B Commerce proof-of-concept built to validate the [Fit-Gap Analysis](../architecture/fit-gap-analysis-portal.md) recommendation (adopt B2B Commerce over the custom LWC portal).
>
> **Date**: 2026-06-06. **Org**: `distribuya-dev` (B2B Commerce enabled).

## What was built (verified live via SOQL)

| Step | Component | Standard object used | Verified |
|---|---|---|---|
| 1 | **DistribuYa Store** | `WebStore` | ✅ |
| 2 | **Catalog + 3 categories** (Alimentos, Bebidas, Limpieza) | `ProductCatalog`, `ProductCategory` | ✅ |
| 2 | **5 products assigned to categories** | `ProductCategoryProduct` | ✅ (Alimentos 2, Bebidas 2, Limpieza 1) |
| 3 | **Buyer Group** (DistribuYa Store Buyer Group, Account-Based) | `BuyerGroup` | ✅ |
| 3 | **Phase-1 "Small Business" Price Book linked** | `BuyerGroupPricebook` | ✅ — the Phase-1 pricebook (5 prices) is reused as-is |
| 3 | Entitlement Policy (All Access) | `CommerceEntitlementPolicy` | ✅ (store default) |
| 4 | **Don Mario - Palermo as active Buyer** | `BuyerAccount` (IsActive=true) | ✅ |
| 4 | Account in buyer group | `BuyerGroupMember` | ✅ |

## The thesis this POC proved

**B2B Commerce reuses the Phase-1 data model with zero rework of the core:**
- `Product2` (the 5 DistribuYa products) — **same records**, no duplication.
- `Pricebook2 "Small Business"` (the Phase-1 segment pricebook with its 5 prices: Aceite 1L=1400, 5L=5800, Detergente=1100, Gaseosa 1.5L=900, 2.25L=1250) — **linked directly to the Buyer Group**. The exact data the custom `PricingService` read is now read by Commerce natively.
- `Account` (Don Mario - Palermo) — **same record**, enabled as a Buyer.

This is the live evidence behind the Fit-Gap recommendation: a wholesale distributor's catalog + per-segment pricing is **configuration in B2B Commerce**, not custom code.

## What the POC deliberately did NOT do (and why)

| Not done | Why |
|---|---|
| Payment gateway integration | Requires a real payment adapter (Apex) or external gateway. This is **Commerce admin/integration work, not architecture** — no portfolio value. A real rollout would integrate the distributor's PO/Net-terms payment process. |
| Full checkout flow / taxes / shipping | Same — operational setup, not a design decision. |
| Activating the storefront experience to production | The catalog + pricing + buyer chain is the architecturally meaningful part; the storefront UI is OOTB and themable. |

**This is the correct scope for a POC**: validate the decision and the data reuse, not build a production storefront.

## Data-model impact of adopting B2B Commerce (carries into an ADR)

| Phase-1 custom object | B2B Commerce standard equivalent | Disposition |
|---|---|---|
| `Product_Category__c` | `ProductCategory` (+ `ProductCategoryProduct`) | **Superseded** by standard — POC used the standard. |
| `Product_Family__c` (variants) | Native Product2 variations | Partially superseded — standard handles variants. |
| `Customer_Price__c` (overrides) | Buyer Group + Entitlement + Price Book | Superseded by the standard pricing mechanism. |
| `Price_Tier__c` (volume) | Native tiered pricing in price books | Superseded. |
| **Account, Product2, Pricebook2, Order, Credit_History__c, Credit_Approval_Tier__mdt** | (reused as-is) | **Kept** — these are the durable core + the Phase-2 differentiator. |

> **Honest note**: this confirms the same process lesson as ADR-0009 — several Phase-1 *catalog/pricing* objects were modeled custom when a standard product (B2B Commerce) already provided them. The Phase-1 *core* (account/product/order/credit) and the Phase-2 *automation* (credit approval) remain valuable and are exactly what stays behind the commerce front end.

## Conclusion

The POC **confirms the Fit-Gap recommendation**. For DistribuYa in production: **adopt B2B Commerce** for the storefront (catalog, categories, buyer-group pricing, cart, checkout, order history, reorder — all OOTB), keep the **Phase-1 core data model** and the **Phase-2 credit-approval automation** (the genuine custom differentiator) behind it. The custom LWC portal remains in the repo as the evaluated POC that informed this decision.

The portfolio value delivered: **a documented build-vs-buy decision (Fit-Gap) + live proof that the standard product reuses the custom data model** — i.e., Architect judgment backed by evidence.
