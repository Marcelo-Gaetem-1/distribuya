# Architecture Decision Records

An Architecture Decision Record (ADR) is a short Markdown document that captures a single architectural decision and the reasoning behind it. In this project, ADRs follow the MADR format extended with a WAF Alignment section (see the template in [subchat-00-decisions.md](../subchat-00-decisions.md#23-plantilla-de-adr-madr--waf)). ADRs are immutable: once accepted, they are never edited. If a decision changes, a new ADR is created with status `Superseded by ADR-XXXX`, and the original is updated only to reflect that it has been superseded. The threshold for writing a formal ADR is: **would reverting this decision require significant rework?** If yes, it gets an ADR.

Files are named `XXXX-title-in-kebab-case.md` and stored in this directory.

## Status

No ADRs written yet. Candidates have been identified during Phase 1 modeling and will be authored during Block B Session 3.

## ADR Candidates

| # | Candidate | Origin | Goes to Subchat 00? | Likely formal ADR? |
|---|---|---|---|---|
| 1 | Pricing model (base + per-customer override) | Scene 1 | Yes | Yes |
| 2 | Approval matrix for orders exceeding credit limit | Scene 1 | Yes | Yes |
| 3 | Stock reservation with timeout | Scene 1 | Yes | Yes |
| 4 | Account with branches + 3 Record Types | Scene 2 + Block B | Yes | Yes |
| 5 | Payment terms and credit evolution | Scenes 1 + 2 | Probably | Maybe |
| 6 | Product variants (Product_Family__c) | Scene 3 + Block B | Yes | Yes |
| 7 | Volume discounts / Price Tiers | Scene 3 | Maybe | Yes |
| 8 | Account Contact Relationships | Block B | No (minor decision, goes in ERD) | No |
| 9 | Credit limit with history (Credit_History__c) | Block B | Yes | Yes |

**Estimated total formal ADRs**: 6–7.
