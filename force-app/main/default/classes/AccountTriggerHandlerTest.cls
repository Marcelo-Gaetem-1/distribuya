/**
 * AccountTriggerHandlerTest — covers branch ownership inheritance (ADR-0007)
 * and credit-limit history capture (ADR-0003).
 */
@isTest
private class AccountTriggerHandlerTest {

    private static Id rtId(String devName) {
        return Account.SObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName().get(devName).getRecordTypeId();
    }

    @isTest
    static void branchInheritsParentOwner() {
        // Parent owned by a distinct active user
        User u = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId() LIMIT 1];

        Account parent = new Account(Name = 'Parent Co', RecordTypeId = rtId('Parent_Customer'));
        insert parent;
        parent.OwnerId = u.Id;
        update parent;

        Test.startTest();
        Account branch = new Account(
            Name = 'Branch 1', RecordTypeId = rtId('Branch_Customer'), ParentId = parent.Id
        );
        insert branch;
        Test.stopTest();

        Account reloaded = [SELECT OwnerId FROM Account WHERE Id = :branch.Id];
        System.assertEquals(u.Id, reloaded.OwnerId, 'Branch should inherit parent owner');
    }

    @isTest
    static void creditLimitChange_writesHistory() {
        Account a = new Account(
            Name = 'Single Co', RecordTypeId = rtId('Single_Customer'), Credit_Limit__c = 1000
        );
        insert a;

        Test.startTest();
        a.Credit_Limit__c = 2500;
        update a;
        Test.stopTest();

        List<Credit_History__c> hist = [
            SELECT Previous_Limit__c, New_Limit__c, Reason__c, Change_Timestamp__c
            FROM Credit_History__c WHERE Account__c = :a.Id
        ];
        System.assertEquals(1, hist.size(), 'One history row expected');
        System.assertEquals(1000, hist[0].Previous_Limit__c);
        System.assertEquals(2500, hist[0].New_Limit__c);
        System.assertNotEquals(null, hist[0].Change_Timestamp__c);
    }

    @isTest
    static void noCreditChange_writesNoHistory() {
        Account a = new Account(
            Name = 'Single Co', RecordTypeId = rtId('Single_Customer'), Credit_Limit__c = 1000
        );
        insert a;

        Test.startTest();
        a.Name = 'Single Co Renamed'; // non-credit change
        update a;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Credit_History__c WHERE Account__c = :a.Id],
            'No history when credit limit unchanged');
    }

    @isTest
    static void bulkCreditChanges_writeHistoryForEach() {
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accts.add(new Account(
                Name = 'Acc ' + i, RecordTypeId = rtId('Single_Customer'), Credit_Limit__c = 500
            ));
        }
        insert accts;

        Test.startTest();
        for (Account a : accts) a.Credit_Limit__c = 900;
        update accts;
        Test.stopTest();

        System.assertEquals(50, [SELECT COUNT() FROM Credit_History__c], 'One history row per changed account');
    }
}
