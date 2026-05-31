/**
 * PricingServiceTest — covers the ADR-0002 cascade: override > tier > base,
 * plus default-segment fallback and bulk behavior.
 */
@isTest
private class PricingServiceTest {

    @TestSetup
    static void setup() {
        Product2 prod = TestDataFactory.newProduct('Widget');
        // Retailer segment pricebook, base price 100
        TestDataFactory.newSegmentPricebookWithEntry('Retailer', prod.Id, 100);
        // Small Business default pricebook, base price 120
        TestDataFactory.newSegmentPricebookWithEntry('Small Business', prod.Id, 120);
    }

    private static Product2 getProduct() {
        return [SELECT Id FROM Product2 WHERE Name = 'Widget' LIMIT 1];
    }
    private static Id getPb(String name) {
        return [SELECT Id FROM Pricebook2 WHERE Name = :name AND IsActive = true LIMIT 1].Id;
    }

    @isTest
    static void basePrice_fromSegmentPricebook() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 prod = getProduct();

        Test.startTest();
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(acc.Id, prod.Id, 1, Date.today())
        );
        Test.stopTest();

        System.assertEquals(PricingService.PriceSource.BASE_PRICE, r.source, 'Should use base price');
        System.assertEquals(100, r.finalPrice, 'Retailer base price');
    }

    @isTest
    static void defaultSegment_whenAccountHasNoSegment() {
        Account acc = TestDataFactory.newAccount('No Segment Co', null);
        Product2 prod = getProduct();

        Test.startTest();
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(acc.Id, prod.Id, 1, Date.today())
        );
        Test.stopTest();

        System.assertEquals(PricingService.PriceSource.BASE_PRICE, r.source);
        System.assertEquals(120, r.finalPrice, 'Falls back to Small Business default pricebook');
    }

    @isTest
    static void customerOverride_winsOverEverything() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 prod = getProduct();
        // tier that would otherwise apply
        TestDataFactory.newTier(prod.Id, getPb('Retailer'), 1, 100, 80);
        // override that must win
        Customer_Price__c cp = TestDataFactory.newOverride(acc.Id, prod.Id, 65, Date.today().addDays(-1), null);

        Test.startTest();
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(acc.Id, prod.Id, 10, Date.today())
        );
        Test.stopTest();

        System.assertEquals(PricingService.PriceSource.CUSTOMER_OVERRIDE, r.source);
        System.assertEquals(65, r.finalPrice);
        System.assertEquals(cp.Id, r.modifierId);
    }

    @isTest
    static void volumeTier_appliesWhenQuantityInRange() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 prod = getProduct();
        Price_Tier__c tier = TestDataFactory.newTier(prod.Id, getPb('Retailer'), 10, 50, 85);

        Test.startTest();
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(acc.Id, prod.Id, 20, Date.today())
        );
        Test.stopTest();

        System.assertEquals(PricingService.PriceSource.VOLUME_TIER, r.source);
        System.assertEquals(85, r.finalPrice);
        System.assertEquals(tier.Id, r.modifierId);
    }

    @isTest
    static void volumeTier_ignoredWhenQuantityBelowMin() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 prod = getProduct();
        TestDataFactory.newTier(prod.Id, getPb('Retailer'), 10, 50, 85);

        Test.startTest();
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(acc.Id, prod.Id, 5, Date.today())
        );
        Test.stopTest();

        System.assertEquals(PricingService.PriceSource.BASE_PRICE, r.source, 'Qty below tier min -> base');
        System.assertEquals(100, r.finalPrice);
    }

    @isTest
    static void expiredOverride_isIgnored() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 prod = getProduct();
        TestDataFactory.newOverride(acc.Id, prod.Id, 50, Date.today().addDays(-30), Date.today().addDays(-1));

        Test.startTest();
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(acc.Id, prod.Id, 1, Date.today())
        );
        Test.stopTest();

        System.assertEquals(PricingService.PriceSource.BASE_PRICE, r.source, 'Expired override ignored');
        System.assertEquals(100, r.finalPrice);
    }

    @isTest
    static void bulk_resolvesManyRequestsWithFixedQueries() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 prod = getProduct();
        List<PricingService.PriceRequest> reqs = new List<PricingService.PriceRequest>();
        for (Integer i = 0; i < 200; i++) {
            reqs.add(new PricingService.PriceRequest(acc.Id, prod.Id, 1, Date.today()));
        }

        Test.startTest();
        List<PricingService.PriceResult> results = PricingService.resolvePrices(reqs);
        Test.stopTest();

        System.assertEquals(200, results.size());
        for (PricingService.PriceResult r : results) {
            System.assertEquals(100, r.finalPrice);
        }
    }

    @isTest
    static void emptyAndNull_inputsAreSafe() {
        System.assertEquals(0, PricingService.resolvePrices(null).size());
        System.assertEquals(0, PricingService.resolvePrices(new List<PricingService.PriceRequest>()).size());
    }
}
