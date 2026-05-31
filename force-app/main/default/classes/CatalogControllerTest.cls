/**
 * CatalogControllerTest — verifies the portal catalog query returns active families
 * with their products and category, and excludes families with no active products.
 */
@isTest
private class CatalogControllerTest {

    @isTest
    static void getCatalog_returnsFamiliesWithProducts() {
        Product_Category__c cat = new Product_Category__c(Name = 'Beverages', Active__c = true);
        insert cat;
        Product_Family__c fam = new Product_Family__c(Name = 'Cola', Brand__c = 'RefresCo', Product_Category__c = cat.Id);
        insert fam;
        Product2 p1 = new Product2(Name = 'Cola 1.5L', IsActive = true, Product_Family__c = fam.Id);
        Product2 p2 = new Product2(Name = 'Cola 2.25L', IsActive = true, Product_Family__c = fam.Id);
        insert new List<Product2>{ p1, p2 };

        Test.startTest();
        List<CatalogController.FamilyDTO> catalog = CatalogController.getCatalog();
        Test.stopTest();

        System.assertEquals(1, catalog.size(), 'One family with products');
        CatalogController.FamilyDTO f = catalog[0];
        System.assertEquals('Cola', f.name);
        System.assertEquals('RefresCo', f.brand);
        System.assertEquals('Beverages', f.categoryName);
        System.assertEquals(2, f.products.size(), 'Two variants');
    }

    @isTest
    static void getCatalog_excludesFamilyWithoutActiveProducts() {
        Product_Family__c fam = new Product_Family__c(Name = 'Empty Family');
        insert fam;
        // a product, but inactive
        insert new Product2(Name = 'Old SKU', IsActive = false, Product_Family__c = fam.Id);

        Test.startTest();
        List<CatalogController.FamilyDTO> catalog = CatalogController.getCatalog();
        Test.stopTest();

        System.assertEquals(0, catalog.size(), 'Family with no active products is excluded');
    }
}
