# Phase 4 — Outbound ERP Order Confirmation: Result (verified live)

> Result of the **standard, no-code** outbound integration chosen in ADR-0010 (Outbound Messages over hand-built Apex). Validated end-to-end on 2026-06-06.

## What was built (declarative, zero code)
1. **Outbound Message** `ERP_Order_Confirmation` (Setup → Outbound Messages): Object = Order, endpoint = mock (webhook.site), fields sent = Id, AccountId, OrderNumber, TotalAmount, Credit_Status__c.
2. **Record-Triggered Flow** `Send_ERP_Order_Confirmation` (after-save on Order, created or updated, entry `Credit_Status__c = Approved`) → action = the Outbound Message. Active.

## Live test
- Set Order **00000114** `Credit_Status__c` → `Approved` (via CLI).
- **Result**: webhook.site received a POST within ~0.001s containing the SOAP/XML notification:
  ```xml
  <sObject xsi:type="sf:Order">
     <sf:Id>801bm000029lXiHAAU</sf:Id>
     <sf:AccountId>001bm000028FNI2AAO</sf:AccountId>   <!-- Don Mario - Palermo -->
     <sf:Credit_Status__c>Approved</sf:Credit_Status__c>
     <sf:OrderNumber>00000114</sf:OrderNumber>
     <sf:TotalAmount>1100.0</sf:TotalAmount>
  </sObject>
  ```
- `user-agent: Jakarta Commons-HttpClient` + `OrganizationId 00Dbm00000HtFW5` confirm it's the genuine Salesforce Outbound Messaging engine.

## Why this matters (the Architect point)
- The full chain **Order approved → Flow → Outbound Message → ERP** works **with no custom code**, and carries **native retry (exponential backoff, 24h) + dead-letter (delivery-failure report)** — exactly the resilience we almost hand-built in Apex (see ADR-0010 revision + LL-030).
- This is the standard→declarative→custom ladder applied to completion: the resilient outbound notification is *configuration*, not code.

## Honest scope / limits
- **SOAP/XML only**: Outbound Messages send SOAP. A REST/JSON ERP would need Flow HTTP Callout or Apex (documented in ADR-0010 as the alternative).
- **Mock endpoint**: webhook.site simulates the ERP receiver; a real ERP would expose its own endpoint via a Named Credential / integration user.
- **Not retrieved to repo as metadata**: Outbound Message + the Flow live in the org (config). They can be retrieved (`Flow` + `WorkflowOutboundMessage` metadata types) if repo versioning is desired — noted as optional follow-up.

## Next in Phase 4
- **Inbound ERP stock sync** — Scheduled Apex upsert of `Product2.Available_Stock__c` by `ERP_Product_ID__c` (Apex justified here: REST + transformation + bulk). This is where `IntegrationLogger` (already built) becomes the audit backbone.
- Logistics + payments integrations.
