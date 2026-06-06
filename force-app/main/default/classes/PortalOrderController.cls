/**
 * PortalOrderController — creates an Order + OrderItems from a portal cart (Phase 3, P3-4/P3-5).
 *
 * One transactional @AuraEnabled call. The order is created as Draft; its Credit_Status is
 * left to the Phase 2 automation (OrderTrigger initializes it; the routing flow/approval
 * process handle credit). Prices come from PricingService via PortalPricingController's
 * source of truth — here we resolve them server-side so the client can't tamper with price.
 */
public with sharing class PortalOrderController {

    public class CartLine {
        @AuraEnabled public Id productId;
        @AuraEnabled public Decimal quantity;
    }

    /**
     * Returns the Account the running portal user belongs to (via their Contact).
     * Lets the catalog component default its order-for account to the logged-in user's
     * own account/branch instead of relying on a hardcoded property.
     * Returns null for internal users with no Contact (e.g. admins previewing).
     */
    @AuraEnabled(cacheable=true)
    public static Id getMyAccountId() {
        User u = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return (u.ContactId != null) ? u.Contact.AccountId : null;
    }

    /**
     * @param accountId the account/branch the order is for
     * @param lines     the cart lines (product + quantity)
     * @return the created Order Id
     */
    @AuraEnabled
    public static Id placeOrder(Id accountId, List<CartLine> lines) {
        if (accountId == null || lines == null || lines.isEmpty()) {
            throw new AuraHandledException('Account and at least one cart line are required.');
        }

        // 1) ENTITLEMENT CHECK in USER_MODE: the running portal user may only order for an
        // account they can actually see (CRUD + FLS + sharing all enforced). If they can't
        // see it, stop. This is the security gate — it runs in the *user's* context.
        List<Account> visible = [SELECT Id FROM Account WHERE Id = :accountId WITH USER_MODE];
        if (visible.isEmpty()) {
            throw new AuraHandledException('You are not authorized to order for this account.');
        }

        // 2) PRIVILEGED WORK in SYSTEM_MODE, scoped to exactly what the portal user is not
        // (and should not be) entitled to: reading Pricebook2/PricebookEntry and writing the
        // order with internal pricing/audit fields. We elevate the minimum, only after the
        // gate above passed — instead of a broad `without sharing` on the whole helper.

        // Segment Pricebook (fallback to Small Business).
        String segment = [SELECT Segment__c FROM Account WHERE Id = :accountId WITH SYSTEM_MODE LIMIT 1].Segment__c;
        String pbName = String.isNotBlank(segment) ? segment : PricingService.DEFAULT_SEGMENT;
        List<Pricebook2> pbs = [SELECT Id FROM Pricebook2 WHERE Name = :pbName AND IsActive = true WITH SYSTEM_MODE LIMIT 1];
        if (pbs.isEmpty()) {
            throw new AuraHandledException('No active pricebook found for segment ' + pbName);
        }
        Id pricebookId = pbs[0].Id;

        // Map product -> PricebookEntry (required on OrderItem).
        Set<Id> productIds = new Set<Id>();
        for (CartLine l : lines) productIds.add(l.productId);
        Map<Id, Id> pbeByProduct = new Map<Id, Id>();
        for (PricebookEntry pe : [
            SELECT Id, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId AND Product2Id IN :productIds AND IsActive = true
            WITH SYSTEM_MODE
        ]) {
            pbeByProduct.put(pe.Product2Id, pe.Id);
        }

        // Price every line via the single source of truth (server-side; anti-tamper).
        List<PricingService.PriceRequest> reqs = new List<PricingService.PriceRequest>();
        for (CartLine l : lines) {
            reqs.add(new PricingService.PriceRequest(accountId, l.productId, l.quantity, Date.today()));
        }
        Map<Id, PricingService.PriceResult> priceByProduct = new Map<Id, PricingService.PriceResult>();
        for (PricingService.PriceResult r : PricingService.resolvePrices(reqs)) {
            priceByProduct.put(r.product2Id, r);
        }

        Order ord = new Order(
            AccountId = accountId,
            Pricebook2Id = pricebookId,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Order_Type__c = 'Standard'
        );
        Database.insert(ord, true, AccessLevel.SYSTEM_MODE);

        List<OrderItem> items = new List<OrderItem>();
        for (CartLine l : lines) {
            Id pbeId = pbeByProduct.get(l.productId);
            if (pbeId == null) {
                throw new AuraHandledException('Product not available in pricebook: ' + l.productId);
            }
            PricingService.PriceResult pr = priceByProduct.get(l.productId);
            Decimal unit = (pr != null && pr.finalPrice != null) ? pr.finalPrice : 0;
            items.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = pbeId,
                Product2Id = l.productId,
                Quantity = (l.quantity == null || l.quantity <= 0) ? 1 : l.quantity,
                UnitPrice = unit,
                Base_Price__c = pr != null ? pr.basePrice : null,
                Applied_Price_Source__c = pr != null ? mapSource(pr.source) : null,
                Price_Modifier_Id__c = pr != null && pr.modifierId != null ? String.valueOf(pr.modifierId) : null
            ));
        }
        Database.insert(items, true, AccessLevel.SYSTEM_MODE);
        return ord.Id;
    }

    private static String mapSource(PricingService.PriceSource s) {
        if (s == PricingService.PriceSource.CUSTOMER_OVERRIDE) return 'Customer_Override';
        if (s == PricingService.PriceSource.VOLUME_TIER) return 'Volume_Tier';
        return 'Base_Price';
    }
}
