# Phase 3 — Experience Cloud Site: Build Guide (UI steps)

Step-by-step to wire the deployed code (3 Apex controllers + 3 LWC) into a portal site.
Org: `distribuya-dev`. Community Plus licenses confirmed available.

## Part A — Create the site
1. Setup -> Digital Experiences -> All Sites -> New.
2. Template: **Build Your Own (LWR)** (LWC-native, matches P3-1).
3. Name `DistribuYa Portal`, URL suffix `distribuya` -> Create. Opens Experience Builder.

## Part B — Place the catalog component
1. In Experience Builder, open Home (or a new "Catalog" page).
2. Components panel -> Custom -> drag **catalogBrowser** onto the canvas.
3. In its properties, set **Account Id (order for)** to a branch Id (e.g. Don Mario - Palermo) for first test.
4. Publish the site.

## Part C — Activate + external users
1. Workspaces -> Administration -> Settings -> Activate.
2. Administration -> Members -> add portal permission sets/profiles.
3. Create a test external user: open a Contact on a customer Account -> Enable Customer User -> Community Plus profile -> assign **PS - Portal Standard / Branch Manager / Account Owner**.

## Part D — ACR Sharing Sets (multi-branch, ADR-0007)
1. Setup -> Digital Experiences -> Sharing Sets -> New.
2. Select portal profile(s). Access Mapping:
   - Account: `Contact.Account` -> `Account`.
   - Order: `Contact.Account` -> `Order.Account`.
3. Test: Don Mario parent user (sees all branches) vs a branch user (own branch only).

## Part E — End-to-end test
1. Log in as the test external user (Login as / portal URL).
2. Browse catalog -> add to cart -> Place Order.
3. Verify internally: new Order (Draft) + OrderItems, priced via PricingService.
4. If over the parent's credit limit -> Phase 2 routing flow creates the approval Task. Full chain works.

## Known follow-ups
- **accountId hardcoded**: enhancement = derive from logged-in user's Contact.Account (small wire change in catalogBrowser).
- **Portal FLS**: ensure catalog fields (Product/Family/Category) have FLS for the portal PS (same pattern as LL-021) or products won't show.
- **Version to repo when done**: `sf project retrieve start --metadata "Network" "ExperienceBundle" -o distribuya-dev`.

## Already done (deployed live)
- CatalogController.getCatalog(); PortalPricingController.getPrice()/getPrices(); PortalOrderController.placeOrder().
- LWC: catalogBrowser (exposed to Experience), productCard, cartSummary.
