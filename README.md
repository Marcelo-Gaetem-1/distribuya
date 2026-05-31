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
| Org Strategy | [docs/architecture/org-strategy.md](docs/architecture/org-strategy.md) |
| Lessons Learned | [docs/lessons-learned.md](docs/lessons-learned.md) |
| Learning Path (skills) | [docs/learning-path.md](docs/learning-path.md) |

---

## Current Status

**Phase 1 — essentially complete. Data model + security model deployed and verified live in a Salesforce Developer Edition org.**

- Block A (Discovery) ✅ — 3 scenes.
- Block B (Modeling) ✅ — Customer, Product, Advanced Pricing, Order, and Sharing domains modeled; 7 ADRs (from 24 candidates); data-model ERD.
- Block D (Materialization) ✅ — deployed & verified live in `distribuya-dev`:
  - **Data model**: Account (6 fields, 3 record types) + Credit_History__c; Product2 + Product_Family__c + Product_Category__c; Customer_Price__c + Price_Tier__c; Order + OrderItem (custom fields) + Stock_Reservation__c + Credit_Approval_Tier__mdt.
  - **Security**: OWD (least-privilege) + 14-role geographic hierarchy + 4 public groups + 6 sharing rules + 11 atomic permission sets + 8 permission set groups + 3 external portal permission sets.
  - **Seed data**: 3 segment Pricebooks.
- **Tracked manual/Phase-3 items**: 3 CMDT record values (CLI-blocked, [manual-deploy/](manual-deploy/README.md)); ACR Sharing Sets (Phase 3, need Experience site).
- **Next**: Phase 2 — Core automation (Flow Orchestration for credit approval, Apex `PricingService`, Platform Events, stock reservation timeout).

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
