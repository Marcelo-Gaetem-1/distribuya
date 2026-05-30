# Architecture Decision Records

An Architecture Decision Record (ADR) is a short Markdown document that captures a single architectural decision and the reasoning behind it. In this project, ADRs follow the MADR format extended with a WAF Alignment section (see the template in [subchat-00-decisions.md](../subchat-00-decisions.md#23-plantilla-de-adr-madr--waf)). ADRs are immutable: once accepted, they are never edited. If a decision changes, a new ADR is created with status `Superseded by ADR-XXXX`, and the original is updated only to reflect that it has been superseded. The threshold for writing a formal ADR is: **would reverting this decision require significant rework?** If yes, it gets an ADR.

Files are named `XXXX-title-in-kebab-case.md` and stored in this directory.

## Status

The first wave of ADRs has been authored during Phase 1 Block B Session 3. The 24 candidates below were consolidated into **7 thematic ADRs** (target was 5–7), each capturing a complete, interconnected architectural decision rather than one atomic sub-decision.

## Authored ADRs

| ADR | Title | Consolidates candidates |
|---|---|---|
| [0001](0001-account-hierarchy-record-type-strategy.md) | Account hierarchy and Record Type strategy | 4, 8 |
| [0002](0002-pricing-architecture.md) | Pricing architecture (segment pricebooks, override, volume tiers) | 1, 7, 10, 11, 12 |
| [0003](0003-credit-limit-traceability.md) | Credit limit traceability (Credit_History__c) | 9, 5 |
| [0004](0004-order-multidimensional-status-model.md) | Order lifecycle — multi-dimensional status model | 14 |
| [0005](0005-credit-approval-orchestration.md) | Credit approval orchestration (Flow Orchestration + Custom Metadata) | 2, 15, 16 |
| [0006](0006-stock-management-and-reservation.md) | Stock management and reservation (hybrid ERP, reservation, timeout) | 3, 17, 18, 19 |
| [0007](0007-sharing-and-security-model.md) | Sharing and security model (OWD, hierarchy, rules, external, PS-led) | 20, 21, 22, 23, 24 |

> Candidates **#13** (OrderItem applied-price traceability) and the lookup detail of **#8** (Account Contact Relationships) are documented in the [data model ERD](../diagrams/data-model-erd.md) rather than as standalone ADRs, per their "No formal ADR" assessment below.

### Planned ADR

| ADR | Title | When |
|---|---|---|
| 0008 | AI Layer org strategy (dedicated Data Cloud DE vs provisioning on core org) | Phase 5 kickoff — interim decision recorded in [org-strategy.md](../org-strategy.md) |

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
| 10 | Pricing — Pricebook segmentation strategy | Phase 1, Block B | Yes | Yes |
| 11 | Pricing — Customer-level override model (Customer_Price__c) | Phase 1, Block B | Yes | Yes |
| 12 | Pricing — Volume-based tiers model (Price_Tier__c) | Phase 1, Block B | Yes | Yes |
| 13 | OrderItem — applied price traceability | Phase 1, Block B | No | No (documented in ERD) |
| 14 | Order — multi-dimensional status model | Phase 1, Block B | Yes | Yes |
| 15 | Order — Flow Orchestration for credit approval | Phase 1, Block B | Yes | Yes |
| 16 | Order — Credit approval matrix via Custom Metadata | Phase 1, Block B | Yes | Yes |
| 17 | Stock — Hybrid model (ERP truth + SF reservation layer) | Phase 1, Block B | Yes | Yes |
| 18 | Stock — Reservation custom object with Lookup | Phase 1, Block B | Yes | Yes |
| 19 | Stock — Time-Triggered Path for reservation expiration | Phase 1, Block B | Yes | Yes |
| 20 | Sharing — OWD model and ownership inheritance for multi-sucursal | Phase 1, Block B | Yes | Yes |
| 21 | Sharing — Role Hierarchy structure (geographic, 4 levels) | Phase 1, Block B | Yes | Yes |
| 22 | Sharing — Sharing Rules strategy and Public Groups | Phase 1, Block B | Yes | Yes |
| 23 | Sharing — External users sharing model with ACR-based Sharing Sets | Phase 1, Block B | Yes | Yes |
| 24 | Sharing — Permission Set-led security model | Phase 1, Block B | Yes | Yes |

**Estimated total formal ADRs**: 6–7.
