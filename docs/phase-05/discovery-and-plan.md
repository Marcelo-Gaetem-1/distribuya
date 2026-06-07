# Phase 5 — AI (Agentforce + Data Cloud): Discovery & Plan

> **Status**: discovery (no build yet). Phase 5 requires a NEW Developer Edition org with Agentforce + Data Cloud (per docs/architecture/org-strategy.md) — `distribuya-dev` (legacy DE) does not include them.

## Goal
Add an AI layer to DistribuYa that demonstrates **Architect judgment over AI**, not just "turn on a chatbot": grounded on real data, standard-first, with clear guardrails (security, hallucination control, cost).

## What each piece is (plain terms)
- **Data Cloud** = unified data brain. Ingests/harmonizes data (Orders, Products, ERP stock, portal activity) into one profile per customer. The *grounding fuel* so AI answers from real data, not invention.
- **Agentforce** = the AI agent that takes actions (check stock, draft an order, review credit), grounded on Data Cloud + Salesforce objects. Built from **Topics** (what it can talk about) + **Actions** (what it can do).

## Candidate use cases (to prioritize with user)
| # | Use case | Who | Value | Standard-first path |
|---|---|---|---|---|
| U1 | **Buyer self-service agent in B2B portal** — "order status?", "is X in stock?", "reorder my usual" | external buyers | deflect support, faster reorders | Agentforce service agent + standard record actions (Order, Product2, Available_Stock__c) |
| U2 | **Credit-risk summary for sales rep** — "summarize this account's credit standing" | internal | faster credit decisions | Prompt template (declarative) grounded on Account + Credit_Status__c |
| U3 | **Demand/stock insight** — "which products are low and reorder soon?" | internal ops | proactive replenishment | Data Cloud segment + prompt; Einstein prediction later |
| U4 | **Order drafting assistant** — natural language → draft Order with PricingService | internal/buyer | speed, fewer errors | Agentforce action wrapping existing Apex PricingService (reuse Phase 2!) |

**Likely first build (highest portfolio value + reuses our foundation): U1** — a portal buyer agent grounded on the Orders/Products/stock we already model. U4 is a strong second because it shows the agent *reusing the Phase-2 Apex service layer* as an invocable action (composability).

## Standard-first ladder for AI (same discipline as ADR-0008)
1. **Standard Agentforce topics/actions** (out-of-box record lookups, no code).
2. **Prompt templates / Flows** (declarative grounding + actions).
3. **Apex invocable actions** only when an agent must call existing business logic (e.g., PricingService, credit-approval) or do something declarative can't.

## Architect concerns to address (this is the judgment showcase)
- **Grounding & hallucination control**: agent must answer from Data Cloud / records, with "I don't know" fallback. Document the grounding sources.
- **Security**: agent runs with a user's permissions — FLS/sharing still apply. Buyer agent must NOT leak other accounts' data (reuse Phase-1 sharing model). Test with a portal/community user.
- **Cost/limits**: Data Cloud credits + Einstein requests are metered; scope the POC small.
- **Trust/audit**: log agent actions; align with the WAF Trusted pillar.

## Prerequisite (BLOCKING — user action)
1. Create a **new Developer Edition with Agentforce + Data Cloud**: https://www.salesforce.com/form/developer-signup/ (the Agentforce/Data Cloud-enabled signup).
2. Provide alias/login → `sf org login web` to connect.
3. Redeploy repo metadata (portable) to the new org so the agent has DistribuYa's data model to ground on.
4. Write **ADR-0011: Phase-5 org strategy** (why a new org; metadata portability) and an **ADR for the AI grounding/agent design**.

## Phase 4 — CLOSED
All three fundamental integration patterns proven live, standard-first, zero/near-zero custom code:
- Outbound (Outbound Message, native retry/dead-letter) — docs/phase-04/outbound-erp-result.md
- Inbound REST upsert by External ID — docs/phase-04/inbound-stock-sync-result.md
- Bulk API upsert by External ID — docs/phase-04/bulk-api-stock-load-result.md
Logistics + payments = same patterns (not rebuilt; documented as such). `IntegrationLogger` remains the audit backbone for any code-based leg.
