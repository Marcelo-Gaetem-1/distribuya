/**
 * TestDataFactory — central test-data builders for DistribuYa (Phase 2 decision P2-6).
 * Keeps tests DRY and consistent; @isTest so it never counts against org code size in prod.
 */
@isTest
public class TestDataFactory {

    public static Account newAccount(String name, String segment) {
        Account a = new Account(Name = name, Segment__c = segment);
        insert a;
        return a;
    }

    public static Product_Family__c newFamily(String name) {
        Product_Family__c f = new Product_Family__c(Name = name);
        insert f;
        return f;
    }

    /** Product2 under a new Product Family (Product_Family__c is a required lookup — Block D / LL-005). */
    public static Product2 newProduct(String name) {
        Product_Family__c f = newFamily(name + ' Family');
        Product2 p = new Product2(Name = name, IsActive = true, Product_Family__c = f.Id);
        insert p;
        return p;
    }

    /** Ensures exactly one standard PricebookEntry exists for the product (prerequisite for custom PBEs). */
    public static void ensureStandardEntry(Id productId, Decimal basePrice) {
        Id stdPbId = Test.getStandardPricebookId();
        List<PricebookEntry> existing = [
            SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :stdPbId AND Product2Id = :productId LIMIT 1
        ];
        if (existing.isEmpty()) {
            insert new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = productId, UnitPrice = basePrice, IsActive = true);
        }
    }

    /**
     * Creates a custom segment Pricebook and a PricebookEntry for the product at basePrice.
     * Ensures the prerequisite standard-pricebook entry exists (only once per product).
     */
    public static Pricebook2 newSegmentPricebookWithEntry(String segmentName, Id productId, Decimal basePrice) {
        ensureStandardEntry(productId, basePrice);
        Pricebook2 pb = new Pricebook2(Name = segmentName, IsActive = true);
        insert pb;
        insert new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = productId,
            UnitPrice = basePrice, IsActive = true
        );
        return pb;
    }

    public static Customer_Price__c newOverride(Id accountId, Id productId, Decimal price, Date eff, Date endD) {
        Customer_Price__c cp = new Customer_Price__c(
            Account__c = accountId, Product2__c = productId,
            Override_Price__c = price, Effective_Date__c = eff, End_Date__c = endD
        );
        insert cp;
        return cp;
    }

    public static Price_Tier__c newTier(Id productId, Id pricebookId, Decimal minQ, Decimal maxQ, Decimal price) {
        Price_Tier__c t = new Price_Tier__c(
            Product2__c = productId, Pricebook2__c = pricebookId,
            Min_Quantity__c = minQ, Max_Quantity__c = maxQ, Tier_Price__c = price
        );
        insert t;
        return t;
    }
}
