# ADR 0003: Credit limit traceability (Credit_History__c)

## Status

Accepted — 2026-05-30 (Phase 1, Block B)

> Consolidates ADR candidate #9 (and the credit-evolution aspect of #5).

## Context and Problem Statement

DistribuYa extends credit to its customers (credit limit, credit used, payment terms that evolve from COD for new customers to Net 15/30/60 based on history). Credit decisions are sensitive and disputable: when a limit is raised, lowered, or terms change, the business must be able to answer *who changed what, when, and why*. We need to decide how much auditability to build into the credit model.

## Decision Drivers

- Auditability and traceability of every credit-relevant change (regulatory/financial discipline — leverages the team's banking background).
- Capture not just the new value but the **reason** and **actor** for each change.
- Avoid over-engineering for a wholesale distributor (no full risk-management subsystem).
- Keep current credit state easy to read on the Account.

## Considered Options

1. **Custom Object `Credit_History__c`** holding one record per change, with timestamp, reason, previous/new values, and owner = related Account.
2. **Fields only on `Account`** (`Credit_Limit__c`, `Credit_Used__c`, `Payment_Terms__c`) relying on standard **Field History Tracking**.
3. **Big Object / external audit store** for high-volume immutable history.

## Decision Outcome

Chosen: **Option 1 — `Credit_History__c`**, because it captures the *reason* and *context* of each change (which Field History Tracking cannot), while staying far lighter than an external audit subsystem.

- Credit state lives on `Account` (`Credit_Limit__c`, `Credit_Used__c` calculated, `Payment_Terms__c`, plus `Customer_Status__c`, `Segment__c`, `Onboarding_Stage__c`).
- Each change writes a `Credit_History__c` row: `Account__c`, `Change_Timestamp__c`, `Reason__c`, previous/new value fields.
- Ownership of `Credit_History__c` follows the related Account (set on insert), feeding the sharing model.

## Pros and Cons of the Options

### Option 1 — Credit_History__c custom object (chosen)
- ✅ Captures reason + actor + business context per change, not just before/after values.
- ✅ Reportable, shareable, and relatable (other entities/automation can reference it).
- ✅ Right-sized: an intermediate between "fields only" and a full audit platform.
- ❌ Requires automation to write history rows on credit changes.
- ❌ Adds a custom object to govern and share.

### Option 2 — Fields only + Field History Tracking
- ✅ Zero custom objects; native.
- ❌ Field History does not capture a free-text reason or business context.
- ❌ Limited retention/visibility and weak reporting compared to a real object.

### Option 3 — Big Object / external store
- ✅ Designed for massive immutable history.
- ❌ Overkill for a wholesale distributor's credit-change volume; harder querying/UX; not justified.

## Consequences

- A trigger/Flow writes `Credit_History__c` rows whenever credit fields change, and stamps owner = Account owner.
- `Credit_History__c` OWD is Private and opened to the Credit & Risk group (see sharing-model ADR); portal users get no access.
- Reporting on credit evolution (limit changes over time, terms progression) is available natively.
- Slight automation cost on credit-field updates.

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive | Full, reasoned audit trail of credit changes — the core driver of this decision. |
| Easy to Change | Neutral | Adds an object + automation, but isolated to the credit domain. |
| Adaptable | Positive | History object can grow new fields (score, source) without touching Account. |
| Resilient | Neutral | No direct resilience impact. |
| Composable | Positive | A first-class history object can be referenced by approvals, reporting, and future risk features. |
