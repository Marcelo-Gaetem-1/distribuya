# Manual-deploy components

Metadata that is **correct in source** but blocked from CLI deployment by known `sf` CLI quirks (not by our design). Each must be applied manually in Setup, or via the Metadata API (mdapi ZIP), once. They are version-controlled here so the source of truth is preserved.

## Seed data (records, not metadata) — for reproducibility in a fresh org

### Segment Pricebooks — DONE ✅
Created as records (Pricebook2 is data, not metadata). To recreate in another org:
```bash
sf data create record -o <org> -s Pricebook2 --values "Name='Retailer' IsActive=true"
sf data create record -o <org> -s Pricebook2 --values "Name='Restaurant' IsActive=true"
sf data create record -o <org> -s Pricebook2 --values "Name='Small Business' IsActive=true"
```
The Order→Pricebook assignment (by Account.Segment__c) is wired in Phase 2 automation (ADR-0002).


## 1. `sharingRules/Account.sharingRules-meta.xml` — DONE manually ✅
- **Blocker**: CLI bug #833 (LL-012) — *"AccountSettings is required for account sharing rules"* fails on CLI deploy even with AccountSettings included.
- **Status**: Created manually in Setup (Account Name ≠ blank → group Credit & Risk, Read Only). Verified live by user.

## 2. `customMetadata/Credit_Approval_Tier.*.md-meta.xml` — TODO ⏳
- **Blocker**: CLI returns `UNKNOWN_EXCEPTION` (server-side) on dry-run AND deploy of these Custom Metadata records in this org (LL-016). Reproduced 3×; not a content error (files are well-formed).
- **What to create** — Setup → Custom Metadata Types → **Credit Approval Tier** → Manage Records → New, 3 records:

| Label / DeveloperName | Min_Ratio__c | Max_Ratio__c | Approver_Role__c |
|---|---|---|---|
| Tier 1 | 0 | 100 | Sales Rep |
| Tier 2 | 100 | 150 | Manager |
| Tier 3 | 150 | *(blank)* | Credit Team |

- **Alternative**: deploy via mdapi ZIP, or retry on a newer `sf` CLI version (current 2.127.2 had the issue; 2.136.8 was available).
