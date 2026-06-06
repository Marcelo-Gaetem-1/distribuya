# Technical Debt & Hardening Backlog — DistribuYa

> Honest, living register of known gaps in security, scalability, and completeness. Surfaced during build and code review. Not blockers for the portfolio demo, but each is the kind of thing an Architect names *before* it bites. Prioritized.

## Security

| # | Gap | Impact | Status |
|---|---|---|---|
| S1 | `Credit_Used__c` is read but never maintained | Exposure ratios use a stale/zero value until a rollup is built | Open — needs Apex/Flow rollup of open approved orders |
| S2 | Per-role FLS on the 11 functional permission sets | End users may not see (or may over-see) fields; only Admin_Field_Access + portal FLS done so far | Open — tracked since LL-021 |
| S3 | Formal security review pass over all Apex | No systematic FLS/CRUD/injection audit yet | Open |
| S4 | Portal FLS completeness | Only Portal Standard has catalog FLS; Branch Manager / Account Owner not yet field-audited | Open |

**Done (was debt, now fixed):** portal Apex hardened with USER_MODE gate + scoped SYSTEM_MODE (LL-023); external sharing model split catalog-public vs customer-private (LL-022); server-side pricing (anti-tamper).

## Scalability

| # | Gap | Impact | Status |
|---|---|---|---|
| P1 | `Credit_Used__c` rollup at scale | A real-time aggregate over thousands of orders per account may be costly | Open — decide rollup vs async maintenance |
| P2 | PricingService query selectivity | At high catalog/customer volume, override/tier lookups need selective filters + indexes | Open — review before high-volume use |
| P3 | No high-volume (200+ bulk, governor-limit) load test | Bulk-safe by design, but unverified at real volume | Open |
| P4 | Trigger framework has no recursion control | Fine now (simple handlers); a growing automation base may re-enter | Open — add a recursion guard if handlers chain |
| P5 | Reservation availability calc deferred (ADR-0006) | Runtime aggregate vs maintained rollup not yet decided | Open — Phase 2/4 |

## Completeness (functional follow-ups)

| # | Item | Status |
|---|---|---|
| F1 | Interactive credit approval | Approval Process built; routing flow built. Multi-tier queue routing simplified to order owner. |
| F2 | ACR multi-branch: Account Owner sees all branches | Sharing Set gives own-account; parent-sees-all-branches mapping needs refinement |
| F3 | Portal: order history / status view for customers | Not built (catalog + place order done) |
| F4 | Integration subscribers for `Order_Approved__e` | Phase 4 (ERP/logistics) |

## How to use this file
- When we knowingly defer something, add a row here instead of letting it vanish.
- Revisit at each phase boundary; promote high-impact items into the active plan.
