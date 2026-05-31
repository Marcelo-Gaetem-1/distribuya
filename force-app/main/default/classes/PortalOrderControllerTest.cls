/**
 * PortalOrderControllerTest — verifies cart -> Order + OrderItems creation with
 * server-resolved pricing (Phase 3).
 */
@isTest
private class PortalOrderControllerTest {

    @isTest
    static void placeOrder_createsOrderWithItems() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 p = TestDataFactory.newProduct('Widget');
        TestDataFactory.newSegmentPricebookWithEntry('Retailer', p.Id, 100);

        PortalOrderController.CartLine line = new PortalOrderController.CartLine();
        line.productId = p.Id;
        line.quantity = 4;

        Test.startTest();
        Id orderId = PortalOrderController.placeOrder(acc.Id, new List<PortalOrderController.CartLine>{ line });
        Test.stopTest();

        Order o = [SELECT Id, AccountId, Status, TotalAmount FROM Order WHERE Id = :orderId];
        System.assertEquals(acc.Id, o.AccountId);
        System.assertEquals('Draft', o.Status);
        OrderItem oi = [SELECT Quantity, UnitPrice, Applied_Price_Source__c FROM OrderItem WHERE OrderId = :orderId];
        System.assertEquals(4, oi.Quantity);
        System.assertEquals(100, oi.UnitPrice, 'Server-resolved base price');
        System.assertEquals('Base_Price', oi.Applied_Price_Source__c);
    }

    @isTest
    static void placeOrder_blankCart_throws() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Test.startTest();
        Boolean threw = false;
        try {
            PortalOrderController.placeOrder(acc.Id, new List<PortalOrderController.CartLine>());
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Empty cart should throw');
    }

    @isTest
    static void placeOrder_productNotInPricebook_throws() {
        Account acc = TestDataFactory.newAccount('Retailer Co', 'Retailer');
        Product2 p = TestDataFactory.newProduct('Widget');
        // Pricebook exists but product NOT added to it
        insert new Pricebook2(Name = 'Retailer', IsActive = true);

        PortalOrderController.CartLine line = new PortalOrderController.CartLine();
        line.productId = p.Id;
        line.quantity = 1;

        Test.startTest();
        Boolean threw = false;
        try {
            PortalOrderController.placeOrder(acc.Id, new List<PortalOrderController.CartLine>{ line });
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Product missing from pricebook should throw');
    }
}
