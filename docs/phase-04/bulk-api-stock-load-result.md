# Phase 4 — Bulk API Stock Load: Result (verified live)

> Demonstrates the **standard Bulk API** doing a masive, asynchronous, batched upsert of stock by External ID — the pattern banks/large distributors use for nightly loads. Validated live on 2026-06-07.

## Why Bulk API (vs REST)
| | REST API | **Bulk API** |
|---|---|---|
| Volume | small, real-time | **thousands/millions**, batched |
| Processing | synchronous, one-by-one | **asynchronous, in batches** |
| Typical use | "update this record now" | "load 2M rows tonight" |
| Config needed | none (standard) | **none (standard)** — only how you invoke it changes |

Same idea as the inbound stock sync (REST, upsert by `ERP_Product_ID__c`), but built for **bulk** — no custom Salesforce code either way.

## The 3-step Bulk flow (observed live)
1. **Create ingest job** → `750bm00000rZZsPAAW` (operation=upsert, object=Product2, externalIdFieldName=ERP_Product_ID__c).
2. **Upload CSV** → processed asynchronously in batches.
3. **Read JobInfo** → `state=JobComplete`, `numberRecordsProcessed=5`, `numberRecordsFailed=0`.

Command (what an ERP middleware would automate):
```
sf data upsert bulk --sobject Product2 --file stock.csv --external-id ERP_Product_ID__c --wait 5
```

## Live test
- **Before**: AC-1L 500, AC-5L 95, DT-900 300, GC-15 800, GC-22 60.
- CSV (simulating the ERP nightly file) upserted by `ERP_Product_ID__c`.
- **After (verified live)**: 480 / 90 / 275 / 750 / 40 — all 5 matched by external key, zero Salesforce code.

## The real error we captured (LL-031)
- First attempt: `state=Failed`, `errorMessage = "ClientInputError : LineEnding is invalid on user data. Current LineEnding setting is CRLF"`.
- Cause: CSV written with LF newlines on Windows while the job expected CRLF.
- Fix: rewrote CSV with CRLF → job completed.
- **Architect point**: Bulk API is **async** — success/failure lives in the **JobInfo**, not the terminal. Always read the job result + failed-records file. This is "capture, don't infer" applied to integrations — exactly how bank Bulk loads surface errors in production.

## Phase 4 status
- ✅ Outbound ERP order confirmation (Outbound Message, standard) — live.
- ✅ Inbound ERP stock sync (REST upsert by External ID, standard) — live.
- ✅ Bulk stock load (Bulk API upsert by External ID, standard) — live, with real error captured/fixed.
- Logistics + payments = same patterns (REST/Bulk + External ID, or Outbound Message), not rebuilt.
