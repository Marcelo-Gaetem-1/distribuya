# ADR 0007: Sharing and security model (OWD, hierarchy, rules, external users, permission-set-led)

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

> Consolidates ADR candidates #20, #21, #22, #23, #24.

> **Materialization update (Block D, 2026-05-30)**: the original Consequences warned Customer Community Plus might be unavailable in a Developer Edition. **Verified empirically in `distribuya-dev`: Customer Community Plus IS available** (5 licenses Active + the `Customer Community Plus User` [PowerCustomerSuccess] profile). The external/portal sharing model is therefore *materializable* in this org, not merely documentable — this removes the previously-flagged Phase 3 risk. 14 roles + 4 public groups deployed.
>
> **Correction — Order OWD changed from ControlledByParent to Private**: the ADR originally set `Order` OWD = ControlledByParent *and* defined two criteria sharing rules on Order (Operations, Finance). These are mutually exclusive — sharing rules cannot exist on a Controlled-by-Parent object (LL-014). Resolved by making **Order OWD = Private**; sales still sees its orders via ownership + role hierarchy, and the Operations/Finance criteria rules now work. OWD verified live: Account=Private, Order=Private, Opportunity=Private (forced, LL-011), Contact=ControlledByParent.
>
> **Sharing rules status**: all 6 done — 5 deployed via CLI (Credit_History, Customer_Price, Stock_Reservation, Order×2) + Account→Credit&Risk created manually (CLI bug LL-012). 
>
> **Permission model status (deployed & verified live)**: 11 atomic internal Permission Sets + 8 Permission Set Groups (per role) + **3 external portal Permission Sets** (Portal Standard / Branch Manager / Account Owner). The portal PSs grant catalog read + order create/edit and **explicitly exclude** Credit_History__c and Stock_Reservation__c, per the ADR's portal visibility matrix.
>
> **Deferred to Phase 3**: the **ACR-based Sharing Sets** (which deliver "Account Owner sees all related branch Accounts" and "Branch Manager sees only own branch") require a DistribuYa Experience Cloud site, which is Phase 3 work. The external Permission Sets are in place; the cross-account record visibility layer is wired when the portal is built.

## Context and Problem Statement

DistribuYa needs a record-visibility and permission model spanning internal commercial/credit/operations/finance teams and external portal users (multi-branch B2B customers). It must keep sensitive data (credit, pricing overrides, stock reservations) restricted, give each function the access it needs, let the multi-branch parent see all its branches, and remain maintainable as the org and roles evolve. We must decide the OWD baseline, the role hierarchy shape, how access is opened (sharing rules vs other), the external-user sharing mechanism, and the profile/permission-set strategy.

## Decision Drivers

- Least-privilege baseline; open access deliberately, not by default.
- Sensitive objects (credit, overrides, reservations) restricted, including from portal users.
- Multi-branch parent must see all its branches without bespoke per-account config.
- New hires inherit access automatically.
- Maintainability and Salesforce's strategic direction (Permission Sets over Profiles).

## Considered Options

1. **Private-baseline OWD + geographic Role Hierarchy + criteria-based Sharing Rules (Public Groups) + ACR-based Sharing Sets for external + Permission-Set-led security.**
2. **Profile-based security** (permissions concentrated in many profiles).
3. **Public OWD + Restriction Rules** to claw back access.
4. **Apex Managed Sharing** as the primary sharing mechanism.

## Decision Outcome

Chosen: **Option 1**. Details:

- **OWD (least-privilege)**: `Account` Private; `Contact`/`Order` Controlled by Parent; `OrderItem` by Master-Detail; catalog objects (`Product2`, `Product_Family__c`, `Product_Category__c`, `Price_Tier__c`) Public Read Only; `Customer_Price__c`, `Credit_History__c`, `Stock_Reservation__c` Private; `Pricebook2` Salesforce-managed.
- **Branch ownership**: a trigger/Flow sets each `Branch_Customer`'s owner = the parent's Sales Rep, so the rep sees all branches via ownership + hierarchy.
- **Role hierarchy**: geographic (territory-based), 4 levels (CEO → Director → Manager → Rep), 14 roles + System Admin outside the hierarchy; "Grant Access Using Hierarchies" enabled.
- **Sharing rules**: 6 criteria-based rules targeting **Public Groups** (`Credit & Risk`, `Operations`, `Finance`, `Catalog Admin`) — e.g. Operations gets approved/in-progress orders and active reservations; Finance gets delivered-unpaid orders; Credit & Risk gets Accounts (R) and `Credit_History__c` (R/W). Groups include roles + subordinates so new hires inherit access.
- **External users**: **Customer Community Plus** + **Sharing Sets** using "All related Accounts via ACR" (no external role hierarchy); 3 tiers (Standard / Branch Manager / Account Owner). Internal-only data (credit, reservations, orchestration runs) hidden from all portal users.
- **Permissions**: **Permission-Set-led** — minimal base profiles (`DistribuYa Internal User`, `DistribuYa Customer Portal User`) + 11 atomic internal Permission Sets composed into 8 Permission Set Groups (one per role) + 3 external Permission Sets.

## Pros and Cons of the Options

### Option 1 — Private baseline + hierarchy + sharing rules + ACR sharing sets + PS-led (chosen)
- ✅ Least-privilege by construction; sensitive data restricted everywhere, including portal.
- ✅ Multi-branch visibility handled natively (ownership + hierarchy internally; ACR Sharing Sets externally).
- ✅ Public Groups + group membership = automatic inheritance for new hires.
- ✅ Permission-Set-led matches Salesforce's strategic investment; atomic PSs compose into roles without bespoke profiles.
- ❌ More moving parts (groups, rules, PSGs) to design and document.
- ❌ Customer Community Plus carries production licensing cost; not available in standard Developer Edition (demoable with the basic Community license, noted as a constraint).

### Option 2 — Profile-based security
- ✅ Familiar.
- ❌ Profile sprawl; against Salesforce's strategic direction; harder to compose one-off roles.

### Option 3 — Public OWD + Restriction Rules
- ✅ Fewer sharing rules.
- ❌ Inverts least-privilege (open then restrict) — riskier for sensitive credit/pricing data.

### Option 4 — Apex Managed Sharing everywhere
- ✅ Maximum flexibility.
- ❌ Heavy custom code for what declarative sharing handles; maintenance burden; reserve for true edge cases only.

## Consequences

- Public Groups, 6 sharing rules, ownership-inheritance automation, and PSG assignments must be built and documented.
- Customer Community Plus is required in production (cost noted); in a Developer Edition the advanced ACR sharing is documented rather than fully demonstrated.
- A one-off custom role is assembled by combining existing atomic Permission Sets rather than creating a new profile.
- Internal-only objects are structurally excluded from portal access.
- Sharing recalculation considerations apply at scale (large group/rule changes).

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Least-privilege baseline; sensitive credit/pricing/reservation data restricted and hidden from portal. |
| Easy to Change | Positive | Public Groups + atomic Permission Sets/PSGs make access changes additive and localized. |
| Adaptable | Positive | New roles compose from existing PSs; ACR Sharing Sets absorb new branch structures. |
| Resilient | Neutral | Security posture, not a runtime-availability concern. |
| Composable | Positive | Atomic Permission Sets and Public Groups are reusable units across roles and future apps. |
