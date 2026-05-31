# Phase 3 — Experience Cloud Site: Build Guide (UI steps)

> Step-by-step to build the DistribuYa B2B portal site in the UI. The code layer (3 Apex controllers + 3 LWC) is **done and deployed live**; this guide wires them into an Experience Cloud site.
>
> **Org**: `distribuya-dev`. Community Plus licenses confirmed available.

## Part A — Create the site

1. **Setup → Digital Experiences → All Sites → New**.
2. Pick a template: **Build Your Own (LWR)** (modern, LWC-native — matches P3-1). 
3. Name: `DistribuYa Portal` · URL suffix: `distribuya` (or similar) → **Create**.
4. Wait for it to provision → it opens **Experience Builder**.

## Part B — Place the catalog component

1. In Experience Builder, open the **Home** page (or create a new page "Catalog").
2. From the **Components** panel (left), find **catalogBrowser** under Custom Components.
3. Drag it onto the page canvas.
4. In its properties (right panel), set **Account Id (order for)** = the account/branch to order for.
   - For a first test: paste a branch Id, e.g. Don Mario - Palermo. (Later this is set dynamically from the logged-in user's account — a small enhancement.)
5. **Publish** the site (top-right).

## Part C — Activate + enable external users

1. **Setup → Digital Experiences → All Sites → [DistribuYa Portal] → Workspaces → Administration → Settings → Activate**.
2. **Members**: Administration → Members → add the **portal permission sets / profiles** so Community Plus users have access.
3. Create a test **external user**:
   - Open a Contact on a customer Account (e.g. a contact on Don Mario - Palermo). If none, create one.
   - On the Contact: button **Enable Customer User** (or Enable Experience User).
   - Profile: a Customer Community Plus-based profile. Assign one of the portal permission sets: **PS - Portal Standard / Branch Manager / Account Owner**.

## Part D — ACR Sharing Sets (the multi-branch magic, ADR-0007)

1. **Setup → Digital Experiences → Sharing Sets → New**.
2. Name: `DistribuYa Portal Sharing` · select the **portal profile(s)**.
3. **Access Mapping**:
   - Object **Account**: User `Contact.Account` → Target `Account` (gives access to their own account).
   - Object **Order**: User `Contact.Account` → Target `Order.Account` (sees orders for their account).
   - For multi-branch (Account Owner sees all branches): this is where ACR + the parent relationship matters; configure the mapping via the related accounts. Test with Don Mario (parent) vs a branch user.
4. Save.

## Part E — End-to-end test

1. Log in as the test external user (use **Login as** from the user record, or the portal login URL).
2. You should see the catalog (catalogBrowser), add products to the cart, and **Place Order**.
3. Verify back in the internal org: a new **Order** (Draft) with **OrderItems**, priced via PricingService.
4. If the order exceeds the parent's credit → Phase 2 routing flow creates the approval Task. Full chain working.

## Notes / known follow-ups

- **accountId hardcoded for now**: the component takes an `@api accountId`. A clean enhancement is to derive it from `UserInfo`/the logged-in user's Contact.Account so each user orders for their own branch automatically. Small Apex/wire change in catalogBrowser.
- **FLS for portal users**: the portal permission sets grant object access; ensure the catalog fields (Product/Family/Category) have FLS for the portal PS (same pattern as LL-021). May need to add field permissions if products don't show.
- **Retrieve to repo when done**: `sf project retrieve start --metadata "Network" "ExperienceBundle" --target-org distribuya-dev` to version the site config.

## What's already done (code layer — deployed live)

- `CatalogController.getCatalog()` — families + products + category (cacheable).
- `PortalPricingController.getPrice()/getPrices()` — wraps PricingService.
- `PortalOrderController.placeOrder(accountId, lines)` — server-priced Order + OrderItems, transactional.
- LWC: `catalogBrowser` (exposed to Experience), `productCard`, `cartSummary`.
