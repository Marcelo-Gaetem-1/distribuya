# Learning Path — Skills to Build (Marcelo)

> **Purpose**: A personalized, evolving list of skills/concepts Marcelo should deepen on the road to **Salesforce Architect**, derived from what actually comes up while building DistribuYa. **Living document** — updated whenever a topic surfaces in our work that's worth studying deliberately.
>
> This is *not* a generic curriculum. Each item is here because it appeared in a real decision or problem in this project. Status: ⬜ to start · 🔄 in progress · ✅ comfortable.

---

## Priority 1 — Data modeling & relationships (active now, Phase 1)

- ⬜ **Relationship types deep-dive**: master-detail vs lookup vs hierarchical; when each is *impossible* (standard object as detail; special objects as lookup targets). → *Surfaced in LL-005, LL-006, LL-007.*
- ⬜ **Delete constraints** (`Cascade` / `Restrict` / `SetNull`) and how they interact with `required`. Be able to justify each choice by data-survival intent. → *LL-004.*
- ⬜ **When to use a custom object vs a picklist vs Custom Metadata Type vs Custom Setting.** You have the picklist-vs-object framework; extend it to CMDT (config) vs records (data). → *Credit_Approval_Tier__mdt decision, ADR-0005.*
- ⬜ **Roll-up summaries and their alternatives** when master-detail isn't available (Apex triggers, Flow, DLRS pattern). → *Product_Family needs this without MD.*
- ⬜ **External IDs & upsert** for integration idempotency. Why `ERP_Product_ID__c` is External Id + Unique. → *ADR-0006.*

## Priority 2 — Salesforce DX & deployment discipline

- ⬜ **Metadata API format**: read/write object, field, record-type XML by hand; know required attributes per field type. → *the whole Block D.*
- ⬜ **`sf` CLI deployment workflow**: `deploy start`, `--dry-run`, `--source-dir`, source-tracking vs non-tracking orgs (and why this org needs `--source-dir`). → *recurring.*
- ⬜ **Source tracking & scratch orgs** (you don't have a Dev Hub yet) — understand the trade-offs vs persistent Developer Edition. → *org-strategy.md.*
- ⬜ **Reading deploy errors fluently** — turn each error message into a precise fix without guessing.

## Priority 3 — Security & sharing model (next, Phase 1 Block D)

- ⬜ **OWD → role hierarchy → sharing rules → manual/Apex sharing** as a layered mental model. → *ADR-0007.*
- ⬜ **Permission-Set-led security**: atomic permission sets → permission set groups → minimal profiles. Salesforce's strategic direction. → *ADR-0007.*
- ⬜ **Account Contact Relationships (ACR)** and **Sharing Sets** for Experience Cloud external users; Community vs Community Plus licensing. → *ADR-0001, ADR-0007.*
- ⬜ **Record Type visibility** — why deployed record types still need permission-set/profile assignment to appear.

## Priority 4 — Automation (Phase 2 horizon)

- ⬜ **Flow Orchestration** (multi-step, multi-user) vs Approval Process (classic) vs Apex. → *ADR-0005.*
- ⬜ **Time-Triggered / Scheduled Paths** in Record-Triggered Flows; granularity vs Scheduled Apex. → *ADR-0006 (reservation timeout).*
- ⬜ **Apex service layer pattern** — a single `PricingService` as the source of pricing truth; testability. → *ADR-0002.*
- ⬜ **Platform Events** for decoupled automation and integration retry/dead-letter. → *Phase 2/4.*

## Priority 5 — Architect craft (cross-cutting, ongoing)

- ⬜ **Well-Architected Framework** — fluently map decisions to the 5 pillars (you're already doing this in ADRs; deepen the "why" per pillar).
- ⬜ **ADR discipline** — writing crisp Context/Drivers/Options/Consequences; knowing what deserves an ADR vs an ERD note. → *the whole adr/ folder.*
- ⬜ **C4 model** diagrams (C1 Lucid, C2/C3 Mermaid) — practice C2/C3 once automation exists.
- ⬜ **Trade-off articulation** — defending a design in an interview: state the rejected options and *why*, not just the chosen one.

## Priority 6 — AI layer (Phase 5 horizon, needs new org)

- ⬜ **Data Cloud** fundamentals: data streams, harmonization, unified profiles, segments. → *org-strategy.md.*
- ⬜ **Agentforce / Agent Builder**: grounding agents on structured + unstructured data; Apex-extending agents.
- ⬜ **When AI belongs in a separate org/environment** and how it consumes core data via integration.

---

## How to use this file

- When a topic comes up in our work that you'd benefit from studying, I add it here with the trigger noted.
- Pick 1–2 ⬜ items per phase to actively study (Trailhead, docs, hands-on in the org) and move them to 🔄 / ✅.
- Items tagged with an `LL-###` or `ADR-####` link back to where they appeared, so studying is grounded in real context.
