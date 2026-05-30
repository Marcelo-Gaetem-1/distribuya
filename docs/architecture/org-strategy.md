# Org Strategy — Deployment Environments

> **Purpose**: Records which Salesforce org(s) DistribuYa is deployed to and why, so the rationale is not lost across sessions. A formal **ADR-0008** will be authored when Phase 5 (AI Layer) begins.
>
> **Status**: Active decision, recorded 2026-05-30 (Phase 1, Block D).

## Decision

| Scope | Org | Notes |
|---|---|---|
| **Phases 1–4** (Foundation, Automation, Experience Cloud, Integrations) | **`distribuya-dev`** — Developer Edition, API 66.0 | The single deploy target for all core metadata. |
| **Phase 5** (AI Layer: Data Cloud + Agentforce) | **New dedicated Developer Edition** (to be created at Phase 5) | A separate org that ships with Agentforce + Data Cloud pre-enabled. |

## Context

The Phase 1–4 org (`distribuya-dev`) is a **classic Developer Edition** and does **not** include Data Cloud or Agentforce. Phase 5 requires those capabilities.

As of TDX '25 (March 2025), Salesforce offers a **free Developer Edition that ships with Agentforce and Data Cloud pre-enabled**, which does not expire as long as it is used at least once every 45 days (sign up at `developer.salesforce.com/signup`). This removes the old 30-day-trial limitation and makes a dedicated AI org the clean path for Phase 5.

## Why two orgs instead of provisioning Data Cloud on the core org

- **Phase 5 is months away.** Creating the AI org now would mean maintaining an org we won't touch for months (and it auto-deletes after 45 days of inactivity). YAGNI.
- **Separation mirrors real enterprise architecture.** An AI/analytics layer commonly lives in a separate environment that *consumes* core data via integration — cleaner story for the portfolio.
- **The repo is portable.** All metadata deploys to any org via `sf project deploy start`. If we later consolidate, Phase 1–4 metadata redeploys to the AI org in minutes. No lock-in.
- **Zero risk of a dead end.** The free Agentforce + Data Cloud Developer Edition exists and is free; Phase 5 is not blocked.

## What was rejected

- **Provisioning Data Cloud on `distribuya-dev` now** — premature; may be unavailable on a classic DE; adds complexity to an environment that just started being built.
- **Using the "Deloitte"-named org** (`mi-dev`) — its name implies real client work, which the project charter explicitly forbids ("not a replica of real client work").

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Neutral | No data-security change; separation keeps AI experimentation isolated from core. |
| Easy to Change | Positive | Portable metadata; environments evolve independently. |
| Adaptable | Positive | Dedicated AI org scales Data Cloud/Agentforce without disturbing the core model. |
| Resilient | Neutral | — |
| Composable | Positive | Core and AI layers are cleanly decoupled, integration-ready. |

## Sources

- [Introducing the New Salesforce Developer Edition, Now with Agentforce and Data Cloud (Salesforce Developers Blog, Mar 2025)](https://developer.salesforce.com/blogs/2025/03/introducing-the-new-salesforce-developer-edition-now-with-agentforce-and-data-cloud)
- [Get Started with Developer Edition with Agentforce and Data Cloud (Salesforce Help)](https://help.salesforce.com/s/articleView?id=xcloud.overview_developer_edition_agentforce_datacloud.htm&language=en_US&type=5)
- [New Salesforce Developer Edition Launched With Agentforce and Data Cloud (Salesforce Ben)](https://www.salesforceben.com/new-salesforce-developer-edition-launched-with-agentforce-and-data-cloud/)
