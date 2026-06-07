# Phase 4 — Inbound ERP Stock Sync: Result (verified live)

> How DistribuYa keeps `Product2.Available_Stock__c` in sync with the ERP (the source of truth for physical stock, per ADR-0006). The Architect question "is this standard?" was applied first — and the answer is **yes, zero code**.

## The ladder applied (standard → declarative → custom)

| Pattern | Who initiates | Standard? | Verdict |
|---|---|---|---|
| **ERP push via REST/Bulk API + upsert by External ID** | ERP → Salesforce | ✅ **100% standard, zero Salesforce code** | **CHOSEN** |
| Salesforce pull via Scheduled Flow + HTTP Callout | Salesforce → ERP | ✅ declarative | fallback if ERP can't push |
| Salesforce pull via Scheduled/Batch Apex | Salesforce → ERP | 🔴 code | only if complex transform/volume |
| Salesforce Connect / External Objects | live external | 🟡 standard but data stays external | doesn't fit (we want a local copy in Product2) |

## Decision: ERP push via standard REST API + External ID upsert
- The ERP calls Salesforce's **standard REST/Bulk API** and **upserts by `ERP_Product_ID__c`** (the External ID we created in Phase 1, ADR-0006).
- **Salesforce builds nothing** — it just exposes its standard API. The External ID is the join key, so the ERP never needs to know Salesforce's internal record Id.
- This is the most common and most standard inbound pattern in the industry.

## Live test (simulating the ERP push)
- **Before**: Aceite Vegetal 5L (`ERP-AC-5L`) `Available_Stock__c = 120`, `Stock_Last_Sync__c = null`.
- Simulated the ERP call: update **matched by `ERP_Product_ID__c = 'ERP-AC-5L'`** (not by Salesforce Id) → `Available_Stock__c = 95`, `Stock_Last_Sync__c` stamped.
- **After (verified live)**: Aceite Vegetal 5L = **95**, sync timestamp set. ✅
- Key point: the match was by the **external key**, exactly how an external system integrates — proving the External ID design from Phase 1 pays off here.

## Why this matters (Architect point)
- Asking "is there a standard way?" **before** building avoided writing Scheduled Apex for what the platform does natively. (Same lesson as LL-030 / the Outbound Messages correction.)
- The `ERP_Product_ID__c` External ID (a Phase-1 modeling decision, ADR-0006) is what makes the zero-code upsert possible — a foundation decision paying dividends two phases later.

## Honest scope / when Apex WOULD be justified
- **Transformation**: if the ERP payload needs mapping/computation before landing in Product2 → a Flow (declarative) or Apex.
- **Salesforce-initiated pull** (ERP can't push): Scheduled Flow + HTTP Callout (declarative first), Scheduled/Batch Apex only for heavy volume/transform — and *there* `IntegrationLogger` becomes the audit backbone.
- **Bulk volume**: the Bulk API (standard) handles large nightly syncs; still no custom Salesforce code.
- This POC simulated a single-record push via CLI; a real integration would use the ERP's middleware/integration user against the same standard API.

## Phase 4 status
- ✅ Outbound ERP order confirmation (Outbound Message, standard) — verified live.
- ✅ Inbound ERP stock sync (REST upsert by External ID, standard) — verified live.
- ⏭️ Logistics + payments integrations (similar patterns).
- `IntegrationLogger` (built) remains the audit backbone for any *code-based* integration leg (transform/pull/bulk error handling).
