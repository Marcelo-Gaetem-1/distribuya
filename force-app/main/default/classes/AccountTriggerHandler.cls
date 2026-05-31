/**
 * AccountTriggerHandler — Account automation for DistribuYa (Phase 2, ADR-0003 / ADR-0007).
 *
 *  - assignBranchOwnership: a Branch_Customer's owner is set to its parent Account's owner,
 *    so the parent's Sales Rep automatically sees all branches (ADR-0007). Before-insert.
 *  - captureCreditHistory: on a credit-limit change, write a Credit_History__c audit row
 *    (who/when/why context lives on the history record) (ADR-0003). After-update.
 *
 * Both are bulk-safe (P2-7): no SOQL/DML inside loops.
 */
public with sharing class AccountTriggerHandler {

    @TestVisible private static final String RT_BRANCH = 'Branch_Customer';

    /** Before insert: Branch accounts inherit their parent's OwnerId. */
    public static void assignBranchOwnership(List<Account> newAccounts) {
        // Resolve the Branch record type id (cached describe; no SOQL).
        Schema.DescribeSObjectResult d = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtByName = d.getRecordTypeInfosByDeveloperName();
        if (!rtByName.containsKey(RT_BRANCH)) return;
        Id branchRtId = rtByName.get(RT_BRANCH).getRecordTypeId();

        Set<Id> parentIds = new Set<Id>();
        for (Account a : newAccounts) {
            if (a.RecordTypeId == branchRtId && a.ParentId != null) {
                parentIds.add(a.ParentId);
            }
        }
        if (parentIds.isEmpty()) return;

        Map<Id, Account> parents = new Map<Id, Account>([
            SELECT Id, OwnerId FROM Account WHERE Id IN :parentIds
        ]);
        for (Account a : newAccounts) {
            if (a.RecordTypeId == branchRtId && a.ParentId != null && parents.containsKey(a.ParentId)) {
                a.OwnerId = parents.get(a.ParentId).OwnerId;
            }
        }
    }

    /** After update: log a Credit_History__c row whenever Credit_Limit__c changes. */
    public static void captureCreditHistory(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Credit_History__c> toInsert = new List<Credit_History__c>();
        for (Account a : newAccounts) {
            Account oldA = oldMap.get(a.Id);
            if (a.Credit_Limit__c != oldA.Credit_Limit__c) {
                toInsert.add(new Credit_History__c(
                    Account__c = a.Id,
                    Change_Timestamp__c = System.now(),
                    Previous_Limit__c = oldA.Credit_Limit__c,
                    New_Limit__c = a.Credit_Limit__c,
                    Reason__c = 'Credit limit changed from ' +
                        formatAmount(oldA.Credit_Limit__c) + ' to ' + formatAmount(a.Credit_Limit__c)
                ));
            }
        }
        if (!toInsert.isEmpty()) insert toInsert;
    }

    private static String formatAmount(Decimal v) {
        return (v == null) ? '(none)' : String.valueOf(v);
    }
}
