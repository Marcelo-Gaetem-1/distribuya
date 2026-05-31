/**
 * CatalogController — read-only catalog data for the B2B portal (Phase 3).
 *
 * Exposes active Product Families with their variant Products and Category, respecting
 * the running user's record access (with sharing). Cacheable for fast portal rendering.
 */
public with sharing class CatalogController {

    public class FamilyDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String brand;
        @AuraEnabled public String imageUrl;
        @AuraEnabled public String categoryName;
        @AuraEnabled public List<ProductDTO> products;
    }

    public class ProductDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal availableStock;
    }

    /** Active families (those with at least one active product), with variants + category. */
    @AuraEnabled(cacheable=true)
    public static List<FamilyDTO> getCatalog() {
        Map<Id, FamilyDTO> byFamily = new Map<Id, FamilyDTO>();

        for (Product_Family__c f : [
            SELECT Id, Name, Brand__c, Image_URL__c, Product_Category__r.Name
            FROM Product_Family__c
            ORDER BY Name
        ]) {
            FamilyDTO dto = new FamilyDTO();
            dto.id = f.Id;
            dto.name = f.Name;
            dto.brand = f.Brand__c;
            dto.imageUrl = f.Image_URL__c;
            dto.categoryName = (f.Product_Category__r != null) ? f.Product_Category__r.Name : null;
            dto.products = new List<ProductDTO>();
            byFamily.put(f.Id, dto);
        }

        for (Product2 p : [
            SELECT Id, Name, Available_Stock__c, Product_Family__c
            FROM Product2
            WHERE IsActive = true AND Product_Family__c IN :byFamily.keySet()
            ORDER BY Name
        ]) {
            ProductDTO pd = new ProductDTO();
            pd.id = p.Id;
            pd.name = p.Name;
            pd.availableStock = p.Available_Stock__c;
            byFamily.get(p.Product_Family__c).products.add(pd);
        }

        // Return only families that actually have active products.
        List<FamilyDTO> result = new List<FamilyDTO>();
        for (FamilyDTO dto : byFamily.values()) {
            if (!dto.products.isEmpty()) result.add(dto);
        }
        return result;
    }
}
