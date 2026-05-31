/**
 * PortalPricingControllerTest — verifies the portal wrapper delegates to PricingService
 * correctly for single and bulk price requests.
 */
@isTest
private class PortalPricingControllerTest {

    @isTest
    static void getPrice_returnsSegmentBasePrice() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 p = TestDataFactory.newProduct('Widget');
        TestDataFactory.newSegmentPricebookWithEntry('Retailer', p.Id, 100);

        Test.startTest();
        PortalPricingController.PriceView v = PortalPricingController.getPrice(acc.Id, p.Id, 1);
        Test.stopTest();

        System.assertEquals(100, v.unitPrice);
        System.assertEquals('BASE_PRICE', v.priceSource);
        System.assertEquals(p.Id, v.productId);
    }

    @isTest
    static void getPrices_bulkCart() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 p = TestDataFactory.newProduct('Widget');
        TestDataFactory.newSegmentPricebookWithEntry('Retailer', p.Id, 100);

        Test.startTest();
        List<PortalPricingController.PriceView> views = PortalPricingController.getPrices(
            acc.Id, new List<Id>{ p.Id }, new List<Decimal>{ 3 }
        );
        Test.stopTest();

        System.assertEquals(1, views.size());
        System.assertEquals(100, views[0].unitPrice);
        System.assertEquals(3, views[0].quantity);
    }
}
