/**
 * CreditExposureService — computes an Order's credit exposure ratio and resolves the
 * approval tier/approver from Credit_Approval_Tier__mdt (ADR-0005).
 *
 * Exposed as an @InvocableMethod so Flow Orchestration (Step 4) can call it from a
 * background step. Pure, bulk-safe logic (ADR-0008: Apex justified for non-trivial,
 * reusable calculation; orchestration itself stays declarative).
 *
 * exposureRatio% = (Credit_Used__c + Order.TotalAmount) / Credit_Limit__c * 100
 */
public with sharing class CreditExposureService {

    public class Request {
        @InvocableVariable(required=true label='Order Id')
        public Id orderId;
    }

    public class Result {
        @InvocableVariable(label='Exposure Ratio (%)')
        public Decimal exposureRatio;
        @InvocableVariable(label='Approver Role')
        public String approverRole;
        @InvocableVariable(label='Tier Label')
        public String tierLabel;
        @InvocableVariable(label='Approval Required')
        public Boolean approvalRequired;
    }

    @InvocableMethod(label='Compute Credit Exposure' description='Returns exposure ratio + approval tier for an Order (ADR-0005)')
    public static List<Result> compute(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) return results;

        Set<Id> orderIds = new Set<Id>();
        for (Request r : requests) if (r.orderId != null) orderIds.add(r.orderId);

        // Credit lives on the parent for branch accounts (ADR-0001): pull both the account's
        // own credit fields and the parent's, then prefer the parent's when present.
        Map<Id, Order> orders = new Map<Id, Order>([
            SELECT Id, TotalAmount,
                   Account.ParentId,
                   Account.Credit_Limit__c, Account.Credit_Used__c,
                   Account.Parent.Credit_Limit__c, Account.Parent.Credit_Used__c
            FROM Order WHERE Id IN :orderIds
        ]);

        // Load tier matrix once (CMDT is cached by the platform).
        List<Credit_Approval_Tier__mdt> tiers = [
            SELECT Label, Min_Ratio__c, Max_Ratio__c, Approver_Role__c
            FROM Credit_Approval_Tier__mdt
        ];

        for (Request req : requests) {
            Result res = new Result();
            Order o = orders.get(req.orderId);
            if (o == null) { results.add(res); continue; }

            // Use the parent's credit when the order's account is a branch (has a parent
            // and no own limit); otherwise use the account's own credit (ADR-0001).
            Decimal limitVal;
            Decimal usedVal;
            if (o.Account != null && o.Account.ParentId != null && o.Account.Credit_Limit__c == null) {
                limitVal = o.Account.Parent.Credit_Limit__c;
                usedVal = (o.Account.Parent.Credit_Used__c != null) ? o.Account.Parent.Credit_Used__c : 0;
            } else if (o.Account != null) {
                limitVal = o.Account.Credit_Limit__c;
                usedVal = (o.Account.Credit_Used__c != null) ? o.Account.Credit_Used__c : 0;
            } else {
                usedVal = 0;
            }
            Decimal orderAmt = (o.TotalAmount != null) ? o.TotalAmount : 0;

            Decimal ratio;
            if (limitVal == null || limitVal == 0) {
                // No/zero limit: maximally exposed -> top tier handles it.
                ratio = 999999;
            } else {
                ratio = ((usedVal + orderAmt) / limitVal) * 100;
            }
            res.exposureRatio = ratio.setScale(2);
            res.approvalRequired = true;

            Credit_Approval_Tier__mdt match = resolveTier(tiers, ratio);
            if (match != null) {
                res.approverRole = match.Approver_Role__c;
                res.tierLabel = match.Label;
            }
            results.add(res);
        }
        return results;
    }

    /** Tier whose [Min_Ratio, Max_Ratio) contains ratio; null Max = open top tier. */
    private static Credit_Approval_Tier__mdt resolveTier(List<Credit_Approval_Tier__mdt> tiers, Decimal ratio) {
        Credit_Approval_Tier__mdt best;
        for (Credit_Approval_Tier__mdt t : tiers) {
            Decimal lo = (t.Min_Ratio__c == null) ? 0 : t.Min_Ratio__c;
            if (ratio < lo) continue;
            if (t.Max_Ratio__c != null && ratio >= t.Max_Ratio__c) continue;
            // Prefer the most specific (highest Min) matching tier.
            if (best == null || lo > ((best.Min_Ratio__c == null) ? 0 : best.Min_Ratio__c)) best = t;
        }
        return best;
    }
}
