# Lessons Learned — DistribuYa

> **Purpose**: Running log of technical/process lessons discovered while building DistribuYa, so we don't repeat the same mistakes in future Salesforce projects. **Living document** — append new entries as they happen, newest at the top of each section.
>
> Format per entry: **What happened → Why → Rule for next time**.

---

## Platform constraints (Salesforce metadata / data model)

### LL-009 — Two fields with the same label confuse the schema
- **What**: `Product2` ended up with the **standard `Product Family` picklist** *and* our **custom `Product_Family__c` lookup**, both showing the label "Product Family" in Schema Builder.
- **Why**: We reused the natural business term as the custom field label without checking the standard object already uses it.
- **Rule**: Before labeling a custom field, check the target (especially standard) object for an existing field with that label. Prefer a distinct label (e.g. "Family" / "Product Family (Catalog)") even if the API name stays `Product_Family__c`. Label collisions hurt reports, list views, and page layouts.

### LL-008 — Currency *formula* fields need BOTH `precision` and `scale`
- **What**: `OrderItem.Discount_Amount__c` (formula, Currency) failed deploy twice: first missing `scale`, then missing `precision`.
- **Why**: Currency/Number fields (including formulas returning currency) require both attributes in metadata XML.
- **Rule**: For any Currency/Number/Percent field, always emit both `<precision>` and `<scale>`. (Display note: Salesforce shows `Currency(14,2)` for `precision=16, scale=2` — the displayed integer length = precision − scale.)

### LL-007 — Lookups to `Product2` cannot be required
- **What**: `Customer_Price__c.Product2__c` and `Stock_Reservation__c.Product2__c` failed: *"Cannot add a lookup relationship child with cascade or restrict options to Product2."*
- **Why**: The platform requires *required* lookups to declare a delete constraint (cascade/restrict), **but `Product2` refuses to be the parent of a cascade/restrict lookup**. The two rules collide, so a required lookup to Product2 is impossible.
- **Rule**: Any lookup **to `Product2`** must be **not-required + `SetNull`**. Enforce "must reference a product" in the app layer (Apex/Flow/validation rule), not the schema. (Likely applies to other special standard objects too — verify per object.)

### LL-006 — Custom lookups to `PricebookEntry` are not allowed
- **What**: `Price_Tier__c.PricebookEntry__c` failed: *"referenceTo value of 'PricebookEntry' does not resolve to a valid sObject type."*
- **Why**: `PricebookEntry` is a special object that cannot be the target of a custom lookup.
- **Rule**: Don't model relationships *to* `PricebookEntry`. To reference a price point, use the coordinate it represents instead: `Product2` + `Pricebook2` lookups. (Several special objects — sharing, history, some pricing/activity objects — can't be lookup targets; verify before designing.)

### LL-005 — A standard object can't be the *detail* side of a master-detail
- **What**: The model called for `Product2` → `Product_Family__c` as Master-Detail with Product2 as the child. Not buildable.
- **Why**: Only custom objects can be the detail side. Standard objects can only be the master.
- **Rule**: When a standard object must be the "child", use a **Lookup** (required + Restrict if you need referential integrity to a custom parent). Roll-ups, if needed, come via Apex/Flow, not master-detail.

### LL-004 — A *required* lookup can't use `SetNull`; pick the constraint to match intent
- **What**: `Credit_History__c.Account__c` failed as `required=true` + `SetNull`: *"must specify either cascade delete or restrict delete for required lookup foreign key."*
- **Why**: A required field can't become null, so `SetNull` contradicts `required`.
- **Rule**: Decide first whether the child must **survive** parent deletion (audit/history → not-required + `SetNull`) or must **block/cascade** (→ required + `Restrict`/`Cascade`). Let the ADR's intent drive the constraint. (Here the ADR said history must survive, so not-required + SetNull was correct — and it exposed that the metadata contradicted the ADR.)

---

## Process / workflow lessons

### LL-003 — Always `--dry-run` before a real deploy
- **What**: Every metadata error in this project (LL-004 through LL-008) was caught by `sf project deploy start --dry-run` **without touching the org**.
- **Rule**: Dry-run is the empirical authority. Never deploy blind; the dry-run is free and non-destructive. Treat its output as the source of truth over any assumption about the platform.

### LL-002 — Search/verify, never assume platform behavior
- **What**: Twice we held off generating metadata to web-search a platform limit (master-detail detail side; PricebookEntry lookups). Both times the assumption we *would* have made was wrong.
- **Rule**: For any platform limit, API version, or feature availability we're not 100% sure of: **web-search or dry-run-test it first**. Salesforce changes fast and these are cheap to verify, expensive to get wrong late.

### LL-001 — The repo is the source of truth, not the chat
- **What**: Decisions live in committed Markdown + deployed metadata, not in conversation memory.
- **Rule**: Close each decision by committing it (snippet/metadata) and pushing. Verify state from `git`/the org, not from recollection. This survives session limits and lets us resume cleanly.

---

## How to use this file

- When something breaks or surprises us, add an `LL-###` entry the same session.
- Reference these in ADRs and PRs (e.g. "per LL-007") so the reasoning is traceable.
- Periodically promote recurring lessons into a personal/team checklist.
