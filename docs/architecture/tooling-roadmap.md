# Tooling & Capability Roadmap — Candidate Additions

> Ideas for tools/capabilities that *could* extend DistribuYa, each evaluated with Architect discipline: **what real requirement it solves**, whether it's **standard or custom**, and the honest **"don't gold-plate" caveat**. A tool is only worth adding when a requirement justifies it — not because it's another logo in the stack.
>
> **Status**: candidates only. None committed. Add a requirement + ADR before building.
>
> **Guiding principle**: the value of an Architect portfolio is *justified decisions*, not tool count. The opposite of "custom without evaluating standard" is "adding standard tools without a requirement." Avoid both.

## How to read this
For each: **Fit** (real DistribuYa use case) · **Std/Custom** (mostly config or build?) · **Connects to** (what we already built) · **Caveat** (when it'd be over-engineering).

## Candidate tools

### 1. Slack — collaboration & notification layer
- **Fit**: (a) **Credit approval in Slack** — approver acts on our Approval Process / `CreditExposureService` request from Slack; (b) **Ops alert** on `Order_Approved__e` → "new approved order" to a fulfillment channel; (c) **Low-stock alert** when the Phase-4 ERP sync flags a tight SKU.
- **Std/Custom**: **Standard** — native "Approvals in Slack" + Slack-Salesforce connector. Little/no custom code.
- **Connects to**: Phase-2 Approval Process + `Order_Approved__e` event; Phase-4 stock sync.
- **Caveat**: don't add Slack just to "use Slack." Justify with a real ask (e.g. "credit team wants to approve without logging into Salesforce"). Notifications-for-everything = noise.

### 2. MuleSoft (or External Services / Named Credentials) — integration backbone
- **Fit**: Phase-4 ERP/logistics/payments integration at enterprise scale (orchestration, transformation, API management).
- **Std/Custom**: Standard product (MuleSoft) vs platform-native (Apex callouts + Named Credentials + Platform Events).
- **Connects to**: Phase-4 plan directly. Our current plan uses platform-native + mocks (right for a Dev-Edition portfolio).
- **Caveat**: MuleSoft is **enterprise-grade and licensed** — overkill for a portfolio POC. Document as "the production answer for complex, multi-system integration"; build the patterns platform-native for the demo. (Already noted in Phase-4 discovery P4-1.)

### 3. Salesforce Flow Orchestration / Approvals — process automation
- **Fit**: the multi-step credit approval (ADR-0005) — we simplified to a routing Flow + Approval Process.
- **Std/Custom**: Standard.
- **Connects to**: Phase-2 credit approval.
- **Caveat**: already partially used. Full Orchestration adds value only if the approval grows multi-stage/multi-user beyond what the Approval Process covers.

### 4. Tableau / CRM Analytics — reporting & demand forecasting
- **Fit**: charter C6 (**demand forecasting**), order/credit/stock dashboards for management.
- **Std/Custom**: Standard products (CRM Analytics native; Tableau licensed).
- **Connects to**: the whole data model (Orders, Stock, Credit). Forecasting is a charter requirement we parked for "Phase 5 / AI".
- **Caveat**: forecasting needs *data volume + history* to be meaningful. In a Dev Edition with seed data it's a demo, not a real model. Reports/dashboards (native) are the pragmatic portfolio piece; Tableau/CRMA is the enterprise upgrade.

### 5. Data Cloud + Agentforce — the AI layer (already planned for Phase 5)
- **Fit**: unified customer profiles, demand forecasting, an agent assisting buyers/credit team.
- **Std/Custom**: Standard (needs a dedicated org — see org-strategy.md).
- **Connects to**: consumes the core data model via integration.
- **Caveat**: genuinely Phase 5; needs the separate Agentforce+Data Cloud org. Already scoped.

### 6. Salesforce Field Service / Maps — delivery & logistics
- **Fit**: a wholesale distributor with **delivery routes** (the charter's "logistics" + "geographic" angle we used for the role hierarchy).
- **Std/Custom**: Standard (Field Service is licensed).
- **Connects to**: Phase-4 logistics integration; fulfillment.
- **Caveat**: a big product for a niche of the demo. Mention as "the route/delivery answer"; don't build it unless delivery scheduling becomes a focus.

### 7. Shield (Platform Encryption / Event Monitoring) — security & compliance
- **Fit**: the credit/financial data (Credit_History, credit limits) in a regulated B2B finance context — the candidate's banking background angle.
- **Std/Custom**: Standard (licensed add-on).
- **Connects to**: the Trusted WAF pillar; Credit_History audit model.
- **Caveat**: enterprise compliance add-on; document as "how I'd harden for a regulated client", not a portfolio build.

## The Architect takeaway (the actual portfolio value)
This table itself is the deliverable: it shows the ability to **survey the ecosystem and decide what fits a requirement vs what would be gold-plating**. For each candidate the honest answer is usually "standard product, document as the production option, don't build unless a requirement appears." That judgment — knowing when *not* to add a tool — is as valuable as knowing how to use one.

## Next-action rule
Before promoting any candidate to a build: (1) write the triggering requirement, (2) confirm standard-vs-custom (ADR-0008 ladder), (3) write an ADR. No tool gets added because it's "useful" in the abstract.
