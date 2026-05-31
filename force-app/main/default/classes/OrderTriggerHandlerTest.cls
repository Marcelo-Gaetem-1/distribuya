/**
 * OrderTriggerHandlerTest — verifies lifecycle defaults on Order insert (ADR-0004).
 */
@isTest
private class OrderTriggerHandlerTest {

    private static Order baseOrder(Id accountId, Id pricebookId) {
        return new Order(AccountId = accountId, Pricebook2Id = pricebookId,
                         EffectiveDate = Date.today(), Status = 'Draft');
    }

    @isTest
    static void defaults_setWhenBlank() {
        Account acc = TestDataFactory.newAccount('Test Co', 'Retailer');
        Id stdPb = Test.getStandardPricebookId();

        Test.startTest();
        Order o = baseOrder(acc.Id, stdPb);
        insert o;
        Test.stopTest();

        Order r = [SELECT Credit_Status__c, Fulfillment_Status__c, Payment_Status__c FROM Order WHERE Id = :o.Id];
        System.assertEquals('Not_Required', r.Credit_Status__c);
        System.assertEquals('Not_Started', r.Fulfillment_Status__c);
        System.assertEquals('Not_Paid', r.Payment_Status__c);
    }

    @isTest
    static void providedCreditStatus_isPreserved() {
        Account acc = TestDataFactory.newAccount('Test Co', 'Retailer');
        Id stdPb = Test.getStandardPricebookId();

        Test.startTest();
        Order o = baseOrder(acc.Id, stdPb);
        o.Credit_Status__c = 'Pending';
        insert o;
        Test.stopTest();

        Order r = [SELECT Credit_Status__c FROM Order WHERE Id = :o.Id];
        System.assertEquals('Pending', r.Credit_Status__c, 'Explicit value must be preserved');
    }

    @isTest
    static void bulkInsert_allInitialized() {
        Account acc = TestDataFactory.newAccount('Test Co', 'Retailer');
        Id stdPb = Test.getStandardPricebookId();
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 50; i++) orders.add(baseOrder(acc.Id, stdPb));

        Test.startTest();
        insert orders;
        Test.stopTest();

        Integer initialized = [SELECT COUNT() FROM Order
            WHERE Credit_Status__c = 'Not_Required' AND Fulfillment_Status__c = 'Not_Started'
            AND Payment_Status__c = 'Not_Paid' AND Id IN :orders];
        System.assertEquals(50, initialized);
    }
}
