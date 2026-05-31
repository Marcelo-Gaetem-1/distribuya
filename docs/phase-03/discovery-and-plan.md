# Phase 3 — Experience Cloud + LWC (B2B Portal): Discovery & Plan

> **Goal**: a self-service B2B portal where DistribuYa customers browse the catalog, see their pricing, and place orders — reusing the Phase 1 data model and Phase 2 automation (PricingService, credit approval, Order_Approved__e).
>
> **Status**: Planning (no build yet). Mirrors the Phase 1/2 discovery approach.
>
> **Hero relevance**: this is where the **ACR Sharing Sets** (ADR-0007) become real — Community Plus is confirmed available in `distribuya-dev`.

## 1. What the portal must do (from the charter + ADR-0007)

| Capability | Notes |
|---|---|
| Customer login (external users) | Customer Community Plus license; 3 tiers: Standard / Branch Manager / Account Owner |
| Browse catalog | Product Families → Products, by Category; read-only |
| See *their* price | Calls **PricingService** (Phase 2) — segment price + overrides + tiers |
| Place an order | Create Order + OrderItems against their Account/branch |
| See their orders | Multi-branch visibility via **ACR Sharing Sets** (Account Owner sees all branches; Branch Manager only own) |
| **Never** see internal data | Credit history, stock reservations, other customers — hidden (portal permission sets already exclude these) |

## 2. Division of labor (important — sets expectations)

| Layer | Who | Why |
|---|---|---|
| **Experience Cloud site** (create, theme, pages, nav, activation) | **Marcelo (UI)** | Site setup is click-only; not authorable as metadata reliably. Claude gives step-by-step. |
| **Guest/login config, ACR Sharing Sets** | **Marcelo (UI)** + Claude guidance | Sharing Sets are configured in Setup; Claude specifies exactly what. |
| **LWC components** (catalog list, product card, price display, cart/order) | **Claude (code)** | Standard LWC + Apex — fully authorable, testable, deployable. |
| **Apex controllers** (`@AuraEnabled`) wrapping PricingService, catalog queries, order creation | **Claude (code)** | The reusable, testable core. |

## 3. Proposed build order

1. **Apex controllers first** (Claude): `CatalogController` (families/products for the running user), `PortalPricingController` (wrap PricingService for the portal context), `PortalOrderController` (create order from cart). With tests. *Dependency-free, deployable now, testable headless.*
2. **LWC components** (Claude): `catalogBrowser`, `productCard`, `cartSummary` — call the controllers. Deployable; previewable.
3. **Experience site** (Marcelo UI): create the site, drop the LWCs on pages, set nav/theme.
4. **External access** (Marcelo UI + Claude spec): enable Community Plus users, assign the 3 portal permission sets (already built), configure **ACR Sharing Sets**.
5. **Test end-to-end**: a portal user logs in, browses, sees their price, places an order → it flows into the Phase 2 automation.

## 4. Key decisions (Phase 3 ADR candidates)

| # | Decision | Lean |
|---|---|---|
| P3-1 | Portal UX framework | LWR (Lightning Web Runtime) site — modern, fast, LWC-native |
| P3-2 | Catalog data source | Apex `@AuraEnabled(cacheable=true)` queries over Product2/Family/Category |
| P3-3 | Pricing in portal | Reuse `PricingService` via a thin `@AuraEnabled` wrapper (no logic duplication) |
| P3-4 | Cart model | Client-side cart in LWC state → single Apex call creates Order + OrderItems transactionally |
| P3-5 | Order submission | Created as Draft + Credit_Status driven by Phase 2 (auto-routes if over limit) |
| P3-6 | Multi-branch | ACR Sharing Sets (ADR-0007); the order's Account = the branch the user is acting for |

## 5. WAF lens

- **Trusted**: portal permission sets exclude internal data; ACR Sharing Sets enforce branch boundaries.
- **Composable**: portal reuses PricingService + order automation — no parallel logic.
- **Adaptable**: LWCs are decoupled from the site; reusable in internal Lightning pages too.
- **Easy to Change**: catalog/pricing changes (data) need no portal code change.

## 6. Constraints / open items

- **Dev Edition**: Community Plus is available (verified); some portal features (e.g. high-volume) may differ from production — note in build.
- **The org is not clean** (pre-existing "Banca Digital Portal"): we create a NEW site for DistribuYa, don't reuse that one.
- LWC preview in a Dev Edition needs the site deployed; we can unit-test controllers headlessly first.

## 7. First concrete step

Claude builds **`CatalogController`** (returns active Product Families with their Products + Category, respecting the running user's access) + tests. Then `PortalPricingController`. Then LWCs. Marcelo creates the site in parallel when ready.
