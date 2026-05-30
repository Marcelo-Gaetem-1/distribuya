# ADR 0001: Account hierarchy and Record Type strategy

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

## Context and Problem Statement

DistribuYa sells to a customer base that is roughly half single-location businesses and half multi-branch organizations (a legal parent entity that owns several physical branches). The two shapes behave very differently:

- A **parent entity** holds the credit limit, credit exposure, and billing relationship, but does **not** place orders directly.
- A **branch** places orders and is fulfilled, but does **not** manage credit on its own.
- A **single-location customer** does both at once.

In addition, the same person (a buyer, an accounts-payable contact) may operate across several branches of the same parent. We need a data model for the customer domain that represents these realities cleanly, keeps credit logic where it belongs, and remains defensible in an Architect review — without scattering conditional logic across every automation and layout.

## Decision Drivers

- Faithful representation of the single vs parent vs branch reality (no forced "one size fits all" record).
- Credit ownership must live unambiguously on the parent / single entity, never on a branch.
- A contact must be relatable to more than one account (multi-branch staffing).
- Stay on Standard objects unless a legitimate reason forces Custom (80/20 rule).
- Minimize conditional logic in flows, validation rules, layouts, and sharing.
- Reuse native platform capabilities so the design ages well across releases.

## Considered Options

1. **Standard `Account` + 3 Record Types + native Account Hierarchy (`ParentId`) + Account Contact Relationships** (for the many-to-many Contact link).
2. **Standard `Account` with a single Record Type** and picklist/checkbox flags (e.g. `Is_Parent__c`, `Is_Branch__c`) to distinguish behavior.
3. **Custom Object** (`Customer__c`) modeling the customer domain from scratch.
4. **Person Accounts** for the customer base.

## Decision Outcome

Chosen: **Option 1 — Standard `Account` with 3 Record Types (`Single_Customer`, `Parent_Customer`, `Branch_Customer`), native Account Hierarchy via `ParentId`, and Account Contact Relationships (ACR)**, because it represents the three customer shapes natively, anchors credit on the parent/single record by design, and uses standard many-to-many for contacts — all without re-implementing platform features.

Concretely:

- **`Account`** is Standard. **Person Accounts are not enabled** (the business is pure B2B).
- **Record Types**: `Single_Customer`, `Parent_Customer`, `Branch_Customer`. Each gets its own page layout and picklist value sets so credit fields appear only where they are meaningful (parent / single) and order-facing fields appear on branches.
- **Hierarchy**: native `ParentId` links each `Branch_Customer` to its `Parent_Customer`. This drives ownership-based visibility (see ADR on the sharing model).
- **`Contact`** is Standard, related to `Account` through **Account Contact Relationships** (many-to-many), so one person can be linked to several branches of the same parent.

## Pros and Cons of the Options

### Option 1 — Standard Account + 3 Record Types + Hierarchy + ACR (chosen)
- ✅ Each customer shape has its own layout, picklists, and (later) automation entry points — no per-record conditional branching.
- ✅ Credit fields live only on parent / single record types, making "branches never carry credit" a structural guarantee, not a runtime check.
- ✅ Native `ParentId` hierarchy feeds "Grant Access Using Hierarchies" and ownership-based sharing for free.
- ✅ ACR is a standard, supported feature that models multi-branch staffing accurately.
- ❌ Three Record Types add configuration surface (layouts, assignment, RT-aware automation).
- ❌ ACR has a learning curve and some reporting nuances versus a simple lookup.

### Option 2 — Single Record Type + flags
- ✅ Simplest initial configuration.
- ❌ Forces conditional logic (`IF Is_Parent__c …`) into validation rules, flows, layouts, and sharing — exactly the smell we want to avoid.
- ❌ Nothing structurally prevents a branch from getting a credit limit; correctness depends on discipline.

### Option 3 — Custom Object `Customer__c`
- ✅ Total modeling freedom.
- ❌ Re-implements Account, its hierarchy, ACR, and the entire ecosystem that expects Account (Orders, Pricebooks, sharing). Violates the 80/20 rule.
- ❌ Not defensible in an Architect interview without one of the four legitimate "go Custom" reasons — none apply here.

### Option 4 — Person Accounts
- ✅ Good fit for B2C / individual consumers.
- ❌ DistribuYa is pure B2B; Person Accounts add irreversible org-wide complexity for a model we do not need.
- ❌ Cannot be turned off once enabled — a heavy, sticky commitment for no benefit.

## Consequences

- Three Record Types must be created with dedicated page layouts and Record Type-aware automation entry points.
- A trigger/Flow will set Branch ownership from the parent (covered in the sharing-model ADR), so branch visibility flows from the hierarchy.
- ACR must be enabled; reporting on contacts will use the ACR junction rather than the direct `AccountId`.
- Credit fields (`Credit_Limit__c`, `Credit_Used__c`, …) are exposed only on `Single_Customer` and `Parent_Customer` layouts.
- No Person Accounts: the org stays on the standard B2B Account/Contact model, keeping sharing and integrations simpler.
- Platform limits/packaging: negligible impact — all features are standard and broadly supported.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Credit ownership is structural (only parent/single carry credit), reducing the risk of misassigned limits. |
| Easy to Change | Positive | Behavior differences live in Record Types/layouts, not in scattered conditional logic, so changes are localized. |
| Adaptable | Positive | Native hierarchy + ACR scale to deep multi-branch structures and new contact relationships without remodeling. |
| Resilient | Neutral | No direct resilience impact; relies on standard, well-tested platform features. |
| Composable | Positive | Reuses Account, hierarchy, and ACR so downstream features (Orders, sharing, portal) plug into standard semantics. |
