# Architecture Diagrams

Diagrams follow the C4 model. C1 (Context) is maintained in Lucid; the export is committed here as an image. C2 (Container) and selective C3 (Component) are maintained as Mermaid diagrams in Markdown files in this folder.

## Available Diagrams

- **[Data Model ERD](data-model-erd.md)** (Mermaid) — logical entity/relationship view of all Phase 1 entities. ✅ Deployed & verified live.
- **[C2 Container](c2-container.md)** (Mermaid) — major building blocks (Core, Automation, Events, Portal, Integration, AI) + external systems. ✅ Added end of Phase 1.

## Planned Diagrams

- **C1 Context** (Lucid) — the DistribuYa system surrounded by external actors (customers, ERP, logistics provider, payment gateway, admin users).
- **C3 Component — Salesforce Core** (Mermaid) — objects, flows, Apex layers, and platform events within the Sales/Service Cloud container.
- **C3 Component — Integration Layer** (Mermaid) — integration patterns, retry logic, and dead-letter handling for ERP, logistics, and payments.

> **Note**: Remaining diagrams will be added as the project progresses through Phases 2–5.
