# DistribuYa — Salesforce Architect Portfolio

DistribuYa is a fictional-but-architecturally-realistic B2B wholesale distributor SaaS built on Salesforce. The platform covers catalog management with per-customer pricing, online order entry, credit-limit approval workflows, ERP/logistics/payments integration, a self-service B2B portal, and demand forecasting. It is developed as a flagship portfolio project to demonstrate Salesforce Architect-level thinking, with every design decision documented and justified.

> **Design lens**: [Well-Architected Framework](https://architect.salesforce.com/well-architected/overview) — every major decision is evaluated against the five WAF pillars: Trusted, Easy to Change, Adaptable, Resilient, and Composable.

---

## Navigation

| Area | Link |
|---|---|
| Project Charter | [docs/project-charter.md](docs/project-charter.md) |
| Architecture Decisions (Subchat 00) | [docs/architecture/subchat-00-decisions.md](docs/architecture/subchat-00-decisions.md) |
| ADR Index | [docs/architecture/adr/README.md](docs/architecture/adr/README.md) |
| Reusable Patterns | [docs/patterns/](docs/patterns/) |
| Phase 1 — Foundation & Data Model | [docs/phase-01/](docs/phase-01/) |
| Phase 2 — Core Automation | [docs/phase-02/discovery-and-plan.md](docs/phase-02/discovery-and-plan.md) |
| Phase 3 — Experience Cloud + LWC (closed) | [docs/phase-03/discovery-and-plan.md](docs/phase-03/discovery-and-plan.md) |
| Phase 4 — Integrations (planning) | [docs/phase-04/discovery-and-plan.md](docs/phase-04/discovery-and-plan.md) |
| Org Strategy | [docs/architecture/org-strategy.md](docs/architecture/org-strategy.md) |
| Fit-Gap Analysis — Portal (build vs buy) | [docs/architecture/fit-gap-analysis-portal.md](docs/architecture/fit-gap-analysis-portal.md) |
| B2B Commerce POC — Result & Conclusion | [docs/phase-03/b2b-commerce-poc-result.md](docs/phase-03/b2b-commerce-poc-result.md) |
| Standard Coverage Validation (requirement by requirement) | [docs/architecture/standard-coverage-validation.md](docs/architecture/standard-coverage-validation.md) |
| Lessons Learned | [docs/lessons-learned.md](docs/lessons-learned.md) |
| Learning Path (skills) | [docs/learning-path.md](docs/learning-path.md) |
| Technical Debt / Hardening Backlog | [docs/technical-debt.md](docs/technical-debt.md) |

---

## Current Status

**Phase 1 — essentially complete. Data model + security model deployed and verified live in a Salesforce Developer Edition org.**

- Block A (Discovery) ✅ — 3 scenes.
- Block B (Modeling) ✅ — Customer, Product, Advanced Pricing, Order, and Sharing domains modeled; 7 ADRs (from 24 candidates); data-model ERD.
- Block D (Materialization) ✅ — deployed & verified live in `distribuya-dev`:
  - **Data model**: Account (6 fields, 3 record types) + Credit_History__c; Product2 + Product_Family__c + Product_Category__c; Customer_Price__c + Price_Tier__c; Order + OrderItem (custom fields) + Stock_Reservation__c + Credit_Approval_Tier__mdt.
  - **Security**: OWD (least-privilege) + 14-role geographic hierarchy + 4 public groups + 6 sharing rules + 11 atomic permission sets + 8 permission set groups + 3 external portal permission sets.
  - **Seed data**: 3 segment Pricebooks.
- **Tracked manual/Phase-3 items**: ACR Sharing Sets (Phase 3, need Experience site); per-role FLS on functional permission sets.

**Phase 2 — Core Automation: essentially complete. All logic deployed & verified live (22 Apex tests passing).**

- ✅ **PricingService** (Apex) — override→tier→base cascade, bulk-safe, reads parent credit for branches.
- ✅ **AccountTrigger** — auto credit-history on limit change + branch ownership inheritance.
- ✅ **Stock Reservation Timeout** (Flow) — Scheduled Path expires stale reservations.
- ✅ **Credit Approval routing** — `CreditExposureService` (invocable) + Record-Triggered Flow creates routed approval Task by tier (CMDT-driven). *Interactive human approval = declarative follow-up (Approval Process), pending org UI availability.*
- ✅ **OrderTrigger** — lifecycle status initialization.
- ✅ **Platform Events** — `Order_Approved__e` published on credit approval (integration seam for Phase 4).
- ✅ **Approval Process** (`Order_Credit_Approval`) — interactive credit approval; field updates drive `Credit_Status`.

**Phase 3 — Experience Cloud + LWC B2B Portal: working end-to-end (happy path verified live).**

- ✅ **Live LWR site** "DistribuYa Portal" with custom LWC: `catalogBrowser`, `productCard`, `cartSummary`.
- ✅ **Apex controllers**: `CatalogController` (catalog), `PortalPricingController` (wraps PricingService), `PortalOrderController` (cart → Order, server-side priced, JSON payload).
- ✅ **Security**: USER_MODE entitlement gate + scoped SYSTEM_MODE; portal permission sets exclude internal data; catalog external-sharing = Read, customer data Private + Sharing Set.
- ✅ **Verified live**: external portal user placed Order 00000114 (priced via PricingService, lifecycle initialized by Phase 2 triggers).

**Phase 3 — CLOSED. The real deliverable is the build-vs-buy decision, made and validated.**

The custom LWC portal (above) was a working **POC**. A formal [Fit-Gap Analysis](docs/architecture/fit-gap-analysis-portal.md) then determined that **B2B Commerce** is the correct choice for a B2B distributor. A staged [B2B Commerce POC](docs/phase-03/b2b-commerce-poc-result.md) **proved live** that the standard product reuses the Phase-1 data model (same Product2, the "Small Business" Pricebook with its prices, Accounts as Buyers) — zero core rework. A [Standard Coverage Validation](docs/architecture/standard-coverage-validation.md) confirmed, requirement by requirement, that **standard covers everything except the tiered credit-approval automation** (Phase 2), which is the one genuinely-justified custom piece and stays behind the storefront.

- **Decision**: adopt B2B Commerce for the storefront; keep Phase-1 core data model + Phase-2 credit automation behind it; custom LWC retained as the evaluated POC.
- **Out of POC scope (by design)**: payment integration, checkout/tax/shipping config, storefront activation — operational admin work, no Architect value (see LL-029).
- **Data-model impact**: `Product_Category__c`, `Product_Family__c`, `Customer_Price__c`, `Price_Tier__c` are superseded by Commerce standard; core objects + credit automation kept.
- **Next**: Phase 4 — Integrations (ERP / logistics / payments), with `Order_Approved__e` as the seam.

---

## Phases

| Phase | Focus | Estimated Duration |
|---|---|---|
| **1** | Foundation and data model | 2 weeks |
| **2** | Core automation (Flow + Apex + Platform Events) | 3 weeks |
| **3** | Experience Cloud + LWC (B2B portal) | 3 weeks |
| **4** | Integrations (ERP, logistics, payments) | 3 weeks |
| **5** | AI Layer (Data Cloud + Model Builder + Agentforce) | 4 weeks |
| **Subchat 00** | Architecture & ADRs (cross-cutting) | ongoing |

---

## Tech Stack

- Salesforce Developer Edition / Trailhead Playground
- Experience Cloud, Apex, LWC, Flow, Platform Events
- Data Cloud + Agentforce (Phase 5)
- Lucid (C1 diagrams), Mermaid (C2/C3 diagrams, versioned in repo)
- GitHub (public), VS Code + Cursor + Claude Code
- Salesforce CLI (sfdx)
