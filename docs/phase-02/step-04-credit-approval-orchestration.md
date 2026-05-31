# Phase 2 — Step 4: Credit Approval Flow Orchestration (Design)

> Implements **ADR-0005** (Flow Orchestration + `Credit_Approval_Tier__mdt`) and the approval matrix from Scene 1 / decisions-log.
>
> **Method**: Apex support class (`CreditExposureService`) built + tested by Claude; the Orchestration itself built in the UI by Marcelo following the step-by-step below. Consistent with ADR-0008 (Apex only for the exposure *calculation*, which is non-trivial and reusable; orchestration stays declarative).

## 1. The business rule (what we're automating)

When an Order needs credit approval, the **exposure ratio** decides who approves:

```
exposureRatio = (Account.Credit_Used__c + thisOrderAmount) / Account.Credit_Limit__c   (as %)
```

| Ratio | Tier (CMDT) | Approver role |
|---|---|---|
| 0–100% | Tier 1 | Sales Rep |
| 100–150% | Tier 2 | Manager |
| 150%+ | Tier 3 | Credit Team |

The tiers live in `Credit_Approval_Tier__mdt` (already populated). The orchestration must **read the matrix** (not hardcode), pick the tier for the computed ratio, route an approval work item to that role, and write the result back to `Order.Credit_Status__c`.

## 2. Why Orchestration (not a plain Flow)

Multi-stage + multi-user + audited (ADR-0005). Flow Orchestration gives native stages, per-stage assignment, and Run history for the audit trail.

## 3. Trigger & scope

- **When**: Order moves to "needs credit approval" — i.e. `Credit_Status__c` set to `Pending` (set by the order-creation step in Step 5, or manually for now).
- The orchestration is a **Record-Triggered Orchestration** on `Order`, condition `Credit_Status__c = Pending`.

## 4. Apex support — `CreditExposureService` (Claude builds this)

Pure, testable logic the orchestration calls via an **InvocableMethod**:

- **Input** (invocable): `List<Request>` where `Request { Id orderId }`.
- **Logic**:
  1. Load the Order + its Account (`Credit_Limit__c`, `Credit_Used__c`) + order amount (`TotalAmount`).
  2. Compute `exposureRatio` (%). Guard divide-by-zero (limit 0 or null → treat as needing top tier).
  3. Query `Credit_Approval_Tier__mdt`, find the tier whose `[Min_Ratio__c, Max_Ratio__c)` contains the ratio (null `Max_Ratio__c` = open top tier).
  4. Return `Result { Decimal exposureRatio; String approverRole; String tierLabel; Boolean approvalRequired; }`.
- **Bulk-safe**; one SOQL for orders, one for CMDT (CMDT can also be read statically).

## 5. Orchestration stages (UI build)

**Orchestration: "Order Credit Approval"** — Record-Triggered on Order, entry `Credit_Status__c = Pending`.

| Stage | Type | What it does |
|---|---|---|
| **1. Analyze Exposure** | Background Step | Calls `CreditExposureService` invocable → stores `approverRole`, `tierLabel`, `exposureRatio` in orchestration variables. |
| **2. Approval Decision** | Interactive Step | Assigns an approval work item to the user/queue for `approverRole`. Screen shows order, amount, ratio, tier. Approver picks Approve / Reject. |
| **3. Apply Decision** | Background Step | Sets `Order.Credit_Status__c` = `Approved` or `Rejected` based on stage-2 outcome. |

(For Tier 1 / Sales Rep, an optional optimization is auto-approve, but keep the interactive step for all tiers initially — simpler and fully audited.)

## 6. Open questions to resolve during build

- **Assignment target**: assign to a *queue* per role vs a specific user. For the demo, assign to the current user / a Credit queue. Production = queues mapped to `Approver_Role__c`.
- **`Credit_Used__c`**: currently a plain field (decisions-log says "calculated"). For Step 4 we read it as-is; a later step maintains it (rollup of open approved orders). Note as dependency, not blocker.
- **`Order.TotalAmount`**: standard field, populated from OrderItems; ensure the test Order has line items.

## 7. WAF alignment

- **Trusted**: approval routing driven by deployable CMDT matrix + native Run history audit.
- **Easy to Change**: change a threshold = edit a CMDT record, no code/flow change.
- **Composable**: `CreditExposureService` reusable (also by an LWC credit widget, or integration).

## 8. Build order

1. ✅/⏳ Claude: `CreditExposureService` + `CreditExposureServiceTest` (deploy, verify).
2. ⏳ Marcelo (UI): build the 3-stage Orchestration calling the invocable.
3. ⏳ Together: test with a real Order (create order + items, set Pending, watch it route).
