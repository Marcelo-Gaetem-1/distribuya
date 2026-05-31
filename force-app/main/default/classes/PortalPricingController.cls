/**
 * PortalPricingController — thin @AuraEnabled wrapper exposing PricingService to the
 * B2B portal LWCs (Phase 3, P3-3). No pricing logic here: it delegates to PricingService
 * so there is a single source of pricing truth (ADR-0002).
 */
public with sharing class PortalPricingController {

    public class PriceView {
        @AuraEnabled public Id productId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public String priceSource;
    }

    /**
     * Returns the effective price for one product/quantity for the given account.
     * @param accountId the account (or branch) the portal user is ordering for
     * @param productId the Product2
     * @param quantity  order quantity
     */
    @AuraEnabled
    public static PriceView getPrice(Id accountId, Id productId, Decimal quantity) {
        PricingService.PriceResult r = PricingService.resolvePrice(
            new PricingService.PriceRequest(accountId, productId, quantity, Date.today())
        );
        return toView(r);
    }

    /** Bulk variant — prices a whole cart in one call (P2-7 bulk-safe end to end). */
    @AuraEnabled
    public static List<PriceView> getPrices(Id accountId, List<Id> productIds, List<Decimal> quantities) {
        List<PricingService.PriceRequest> reqs = new List<PricingService.PriceRequest>();
        for (Integer i = 0; i < productIds.size(); i++) {
            Decimal q = (quantities != null && i < quantities.size()) ? quantities[i] : 1;
            reqs.add(new PricingService.PriceRequest(accountId, productIds[i], q, Date.today()));
        }
        List<PriceView> views = new List<PriceView>();
        for (PricingService.PriceResult r : PricingService.resolvePrices(reqs)) {
            views.add(toView(r));
        }
        return views;
    }

    private static PriceView toView(PricingService.PriceResult r) {
        PriceView v = new PriceView();
        v.productId = r.product2Id;
        v.quantity = r.quantity;
        v.unitPrice = r.finalPrice;
        v.priceSource = String.valueOf(r.source);
        return v;
    }
}
