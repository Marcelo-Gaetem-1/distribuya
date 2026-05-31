/**
 * CreditExposureServiceTest — verifies exposure ratio computation and tier resolution
 * against the live Credit_Approval_Tier__mdt matrix (Tier1 0-100 Sales Rep,
 * Tier2 100-150 Manager, Tier3 150+ Credit Team).
 *
 * NOTE: reads real CMDT records (CMDT isn't isolated by test context). Assertions on
 * approverRole assume the standard tiers exist in the org.
 */
@isTest
private class CreditExposureServiceTest {

    private static Order buildOrder(Decimal creditLimit, Decimal creditUsed, Decimal qty, Decimal unitPrice) {
        Account acc = TestDataFactory.newAccount('Test Co', 'Retailer');
        acc.Credit_Limit__c = creditLimit;
        acc.Credit_Used__c = creditUsed;
        update acc;
        Product2 p = TestDataFactory.newProduct('Widget');
        Pricebook2 pb = TestDataFactory.newSegmentPricebookWithEntry('Retailer', p.Id, unitPrice);
        return TestDataFactory.newOrderWithItem(acc.Id, pb.Id, p.Id, qty, unitPrice);
    }

    private static CreditExposureService.Result run(Id orderId) {
        CreditExposureService.Request req = new CreditExposureService.Request();
        req.orderId = orderId;
        return CreditExposureService.compute(new List<CreditExposureService.Request>{ req })[0];
    }

    @isTest
    static void tier1_lowExposure_salesRep() {
        // limit 10000, used 0, order 1x5000 = 5000 -> 50% -> Tier 1
        Order o = buildOrder(10000, 0, 1, 5000);
        Test.startTest();
        CreditExposureService.Result r = run(o.Id);
        Test.stopTest();
        System.assertEquals(50, r.exposureRatio, 'Ratio should be 50%');
        System.assertEquals('Sales Rep', r.approverRole, 'Tier 1 -> Sales Rep');
    }

    @isTest
    static void tier2_midExposure_manager() {
        // limit 10000, used 8000, order 1x4000 = 12000 -> 120% -> Tier 2
        Order o = buildOrder(10000, 8000, 1, 4000);
        Test.startTest();
        CreditExposureService.Result r = run(o.Id);
        Test.stopTest();
        System.assertEquals(120, r.exposureRatio);
        System.assertEquals('Manager', r.approverRole, 'Tier 2 -> Manager');
    }

    @isTest
    static void tier3_highExposure_creditTeam() {
        // limit 10000, used 10000, order 1x6000 = 16000 -> 160% -> Tier 3
        Order o = buildOrder(10000, 10000, 1, 6000);
        Test.startTest();
        CreditExposureService.Result r = run(o.Id);
        Test.stopTest();
        System.assertEquals(160, r.exposureRatio);
        System.assertEquals('Credit Team', r.approverRole, 'Tier 3 -> Credit Team');
    }

    @isTest
    static void zeroLimit_routesToTopTier() {
        Order o = buildOrder(0, 0, 1, 1000);
        Test.startTest();
        CreditExposureService.Result r = run(o.Id);
        Test.stopTest();
        System.assertEquals('Credit Team', r.approverRole, 'Zero limit -> top tier');
    }

    @isTest
    static void emptyInput_isSafe() {
        System.assertEquals(0, CreditExposureService.compute(new List<CreditExposureService.Request>()).size());
        System.assertEquals(0, CreditExposureService.compute(null).size());
    }
}
