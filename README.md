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

---

## Current Status

**Phase 1 Block B — Modeling is complete. Ready for Block D (materialization).**

- Block A (Discovery) is closed — 3 scenes completed.
- Block B (Modeling) is closed — Customer, Product, Advanced Pricing, Order, and Sharing domains all modeled and documented.
- 7 formal ADRs authored (consolidated from 24 candidates) — see [docs/architecture/adr/](docs/architecture/adr/).
- Data model ERD published — see [docs/architecture/diagrams/data-model-erd.md](docs/architecture/diagrams/data-model-erd.md).
- **Next**: Block D — materialize metadata into `force-app/main/default/objects/` and push to a Salesforce Developer Edition org.

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
