# Lessons Learned — DistribuYa

> **Purpose**: Running log of technical/process lessons discovered while building DistribuYa, so we don't repeat the same mistakes in future Salesforce projects. **Living document** — append new entries as they happen, newest at the top of each section.
>
> Format per entry: **What happened → Why → Rule for next time**.

---

## Apex / automation (Phase 2)

### LL-019 — Test data must satisfy the data model's own required fields and uniqueness
- **What**: PricingService tests failed first with `REQUIRED_FIELD_MISSING [Product_Family__c]` then `DUPLICATE_VALUE` on PricebookEntry.
- **Why**: Our Block D model made `Product2.Product_Family__c` a required lookup (LL-005), and a product can have only one standard PricebookEntry — but the factory inserted a standard PBE per segment-pricebook call.
- **Rule**: A green test suite validates the data model too. Factories must (a) populate required custom fields, (b) create prerequisite parents (Product Family), (c) be idempotent for shared rows (one standard PBE per product via an existence check). The required-field failure was *good news* — it proved the schema constraint works.

### LL-018 — `global` (and other access modifiers) are reserved words in Apex
- **What**: Compile failed with *"Unexpected token 'global'"* — a local variable was named `global`.
- **Rule**: Never name variables with Apex reserved words (`global`, `public`, `system`, `trigger`, `with`, etc.). Renamed to `globalTier`.

### LL-017 — Run Apex tests on deploy and parse coverage from JSON
- **What**: `sf project deploy start --test-level RunSpecifiedTests --tests <Class> --json` runs tests during deploy; failures appear under `result.details.runTestResult.failures`, coverage under `codeCoverage`.
- **Rule**: Always deploy Apex with its tests (never blind). Parse the JSON to a file + read it (avoids the stderr-warning corruption seen with pipes). PricingService landed at 94% (8/8), well above the 75% platform minimum.

## Platform constraints (Salesforce metadata / data model)

### LL-016 — CLI may throw UNKNOWN_EXCEPTION deploying Custom Metadata records; isolate, don't guess
- **What**: Deploying 3 `Credit_Approval_Tier__mdt` records returned `UNKNOWN_EXCEPTION: An unexpected error occurred... ErrorId ...` on dry-run AND real deploy, with TOTAL=0. Reproduced 3×; files well-formed; CMDT records can't be created via `sf data create record` either (need Metadata API).
- **Diagnosis technique that worked**: temporarily move the CMDT files out → the dry-run then surfaced a *different, real* error (the Account sharing rule) that the UNKNOWN_EXCEPTION had masked, and TOTAL/error counts were unstable. Putting them back reproduced the exception → isolated the cause to the CMDT records + this CLI/org combo.
- **Rule**: A `UNKNOWN_EXCEPTION` with TOTAL=0 is a server/CLI failure, not your metadata. Don't burn cycles editing the files. Isolate by removing suspect components to see what's masked, then fall back to: manual creation in Setup, mdapi ZIP, or a newer CLI version. Tracked in `manual-deploy/`.
- **Follow-up (this org)**: creating the records manually in Setup left all custom fields `null` because the 3 custom fields weren't on the CMDT page layout (the "New" form only showed Label + Name). And **CMDT records can't be patched via `sf data update`** — fails `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY: entity type cannot be updated`. CMDT is Metadata-API-only for field values. Resolution path: add the 3 fields to the CMDT page layout once, then edit each record's values in Setup. **Takeaway**: for CMDT, add custom fields to the layout *before* creating records, or the create form silently omits them.

### LL-015 — A Permission Set Group can't share an API name with a Permission Set; PSGs can't nest
- **What**: PSGs `Credit_Analyst` and `Credit_Manager` failed: *"The API name you entered is already in use"* — same API names as the existing atomic Permission Sets.
- **Why**: PSGs and PSs share the same API-name namespace. Also, a PSG cannot contain another PSG — it only lists atomic Permission Sets.
- **Rule**: Give PSGs a distinct API name (e.g. suffix `_PSG`) when a same-named PS exists. Compose roles by listing the atomic PSs directly (e.g. Sales Manager PSG lists all of Rep's PSs + Tier 2), since nesting isn't allowed.

### LL-014 — You can't have sharing rules on an object whose OWD is Controlled by Parent
- **What**: ADR-0007 specified `Order` OWD = ControlledByParent *and* two sharing rules on Order (Operations, Finance). Deploy rejected the rules: *"not supported for object Order since its org wide default is 'Controlled By Parent'."*
- **Why**: Sharing rules only apply to objects with OWD Private or Public Read Only. A Controlled-by-Parent object inherits all access from its parent, so rules would be contradictory. This was an **internal contradiction in the ADR itself**.
- **Rule**: If a parallel team (not in the owner's role-hierarchy branch) needs access to records by *field criteria*, the object's OWD must be **Private**, not Controlled by Parent. Decision: Order → Private (sales still sees its orders via ownership + role hierarchy). ADR-0007 corrected. Catch these contradictions by listing, per object, {OWD} vs {does it have sharing rules?} before materializing.

### LL-013 — Criteria-based sharing rule fields are type-restricted (no Currency)
- **What**: `Customer_Price__c` rule with criteria on `Override_Price__c` (Currency) failed: *"not valid workflow field."*
- **Why**: Criteria sharing-rule fields are limited to Auto Number, Checkbox, Date/Time, Email, Number, Percent, Phone, Picklist, Text/Text Area, URL, **Lookup** — **not Currency**.
- **Rule**: For an "all records" criteria rule, pick an always-populated allowed-type field (a required Lookup like `Account__c`, or `Name notEqual ''`). Never use Currency/Formula fields as criteria.

### LL-012 — Account sharing rules + AccountSettings deploy is blocked by a known CLI bug
- **What**: Deploying an Account criteria sharing rule fails with *"AccountSettings is required for account sharing rules"* — even when `AccountSettings` (with `enableAccountOwnerReport=true`) is deployed first, deployed together via `--source-dir`, or referenced together in a `--manifest` package.xml. Known issue: forcedotcom/cli #833.
- **Why**: A `sf` CLI packaging bug for the Account+AccountSettings+SharingRules combination; not a metadata error on our side (Account OWD is correctly Private).
- **Rule / workaround**: Don't burn time fighting it via CLI. Options: (a) create the single Account sharing rule **manually in Setup** (1 min), or (b) deploy via the older Metadata API (`mdapi`) ZIP, or (c) retry on a newer CLI version. For DistribuYa: the other 5 rules deploy fine; the Account→Credit&Risk rule is tracked as a manual step. **Always-verify note**: confirmed by reproducing 3 deploy variants, not assumed.

### LL-011 — Setting Account OWD to Private forces its standard child objects too
- **What**: Deploying `Account` OWD = Private failed: *"ReadWrite is not a valid sharing model for Opportunity when Account sharing model is Private."* Then `Opportunity = ControlledByParent` ALSO failed (*"ControlledByParent is not a valid sharing model for Opportunity"*).
- **Why**: Objects that hang off Account in the standard model (**Opportunity**, **Case**) can't be more open than Account. And **Opportunity does not support `ControlledByParent`** — its only valid OWDs are Private / Read / ReadWrite. So with Account Private, Opportunity must be **Private**. (Contact and Order *do* accept `ControlledByParent`.)
- **Rule**: When setting Account to Private, in the SAME deployment set Opportunity = **Private** (not ControlledByParent) and review Case. Know which objects accept `ControlledByParent` (Contact, Order) vs which don't (Opportunity).
- **Note**: `EntityDefinition.InternalSharingModel` reports the *effective* model — Contact/Order show "Private" when they're ControlledByParent under a Private Account. That's expected, not a deploy failure.

### LL-010 — Trust the fresh run, not a re-read of stale output
- **What**: After fixing Opportunity to Private, repeated parses kept showing the *previous* error. Root cause: re-reading old/empty redirected JSON files and garbled terminal text, not the latest run.
- **Rule**: Verify a run by its own `startDate`/exit code; write each run to a *unique* file or parse inline. When `sf --json` output looks empty or garbled (PowerShell encoding/parallel-call artifacts), re-capture cleanly and Read it — don't trust on-screen text. Keep deploy/verify commands sequential, not parallel.

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
