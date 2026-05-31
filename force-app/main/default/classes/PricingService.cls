/**
 * PricingService — single source of pricing truth for DistribuYa.
 *
 * Resolves the effective unit price for an (Account, Product, Quantity, Date) using the
 * cascade defined in ADR-0002:  customer override  ->  volume tier  ->  base segment price.
 *
 * Design (Phase 2 decisions):
 *  - P2-3: one public entry point resolvePrice(); bulk twin resolvePrices() for trigger/bulk use.
 *  - P2-7: fully bulk-safe — fixed number of SOQL queries regardless of input size.
 *
 * Base price comes from the segment Pricebook (Account.Segment__c -> Pricebook2 by name);
 * accounts with no segment fall back to the "Small Business" Pricebook (ADR-0002).
 */
public with sharing class PricingService {

    public enum PriceSource { BASE_PRICE, CUSTOMER_OVERRIDE, VOLUME_TIER }

    /** Default segment Pricebook used when an Account has no Segment__c. */
    public static final String DEFAULT_SEGMENT = 'Small Business';

    public class PriceRequest {
        public Id accountId;
        public Id product2Id;
        public Decimal quantity;
        public Date asOf;
        public PriceRequest(Id accountId, Id product2Id, Decimal quantity, Date asOf) {
            this.accountId = accountId;
            this.product2Id = product2Id;
            this.quantity = (quantity == null || quantity <= 0) ? 1 : quantity;
            this.asOf = (asOf == null) ? Date.today() : asOf;
        }
    }

    public class PriceResult {
        public Id accountId;
        public Id product2Id;
        public Decimal quantity;
        public Decimal basePrice;     // segment Pricebook price (may be null if no entry)
        public Decimal finalPrice;    // price after applying the cascade
        public PriceSource source;    // which mechanism produced finalPrice
        public Id modifierId;         // Customer_Price__c or Price_Tier__c id, when applicable
    }

    /** Single-request convenience entry point. */
    public static PriceResult resolvePrice(PriceRequest req) {
        return resolvePrices(new List<PriceRequest>{ req })[0];
    }

    /** Bulk entry point — the canonical implementation. Fixed SOQL count. */
    public static List<PriceResult> resolvePrices(List<PriceRequest> requests) {
        List<PriceResult> results = new List<PriceResult>();
        if (requests == null || requests.isEmpty()) return results;

        Set<Id> accountIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        for (PriceRequest r : requests) {
            if (r.accountId != null) accountIds.add(r.accountId);
            if (r.product2Id != null) productIds.add(r.product2Id);
        }

        // 1) Account -> Segment
        Map<Id, String> accountSegment = new Map<Id, String>();
        for (Account a : [SELECT Id, Segment__c FROM Account WHERE Id IN :accountIds]) {
            accountSegment.put(a.Id, a.Segment__c);
        }

        // 2) Segment name -> Pricebook2 Id (segment Pricebook names match Segment__c values)
        Set<String> segmentNames = new Set<String>{ DEFAULT_SEGMENT };
        for (String s : accountSegment.values()) {
            if (String.isNotBlank(s)) segmentNames.add(s);
        }
        Map<String, Id> segmentToPricebook = new Map<String, Id>();
        for (Pricebook2 pb : [SELECT Id, Name FROM Pricebook2 WHERE Name IN :segmentNames AND IsActive = true]) {
            segmentToPricebook.put(pb.Name, pb.Id);
        }

        // 3) Base prices: PricebookEntry keyed by pricebookId|productId
        Set<Id> pricebookIds = new Set<Id>(segmentToPricebook.values());
        Map<String, Decimal> baseByPbProduct = new Map<String, Decimal>();
        if (!pricebookIds.isEmpty() && !productIds.isEmpty()) {
            for (PricebookEntry pe : [
                SELECT Pricebook2Id, Product2Id, UnitPrice
                FROM PricebookEntry
                WHERE Pricebook2Id IN :pricebookIds AND Product2Id IN :productIds AND IsActive = true
            ]) {
                baseByPbProduct.put(pe.Pricebook2Id + '|' + pe.Product2Id, pe.UnitPrice);
            }
        }

        // 4) Customer overrides keyed by accountId|productId (date-filtered in memory for null-safety)
        Map<String, List<Customer_Price__c>> overridesByKey = new Map<String, List<Customer_Price__c>>();
        for (Customer_Price__c cp : [
            SELECT Id, Account__c, Product2__c, Override_Price__c, Effective_Date__c, End_Date__c
            FROM Customer_Price__c
            WHERE Account__c IN :accountIds AND Product2__c IN :productIds
        ]) {
            String k = cp.Account__c + '|' + cp.Product2__c;
            if (!overridesByKey.containsKey(k)) overridesByKey.put(k, new List<Customer_Price__c>());
            overridesByKey.get(k).add(cp);
        }

        // 5) Volume tiers keyed by productId
        Map<Id, List<Price_Tier__c>> tiersByProduct = new Map<Id, List<Price_Tier__c>>();
        for (Price_Tier__c t : [
            SELECT Id, Product2__c, Pricebook2__c, Min_Quantity__c, Max_Quantity__c,
                   Tier_Price__c, Effective_Date__c, End_Date__c
            FROM Price_Tier__c
            WHERE Product2__c IN :productIds
        ]) {
            if (!tiersByProduct.containsKey(t.Product2__c)) tiersByProduct.put(t.Product2__c, new List<Price_Tier__c>());
            tiersByProduct.get(t.Product2__c).add(t);
        }

        // 6) Resolve each request through the cascade
        for (PriceRequest r : requests) {
            PriceResult res = new PriceResult();
            res.accountId = r.accountId;
            res.product2Id = r.product2Id;
            res.quantity = r.quantity;

            String segment = accountSegment.get(r.accountId);
            Id pbId = String.isNotBlank(segment) ? segmentToPricebook.get(segment) : null;
            if (pbId == null) pbId = segmentToPricebook.get(DEFAULT_SEGMENT);

            res.basePrice = (pbId != null) ? baseByPbProduct.get(pbId + '|' + r.product2Id) : null;

            // 6a) customer override (highest precedence)
            Customer_Price__c ov = pickActiveOverride(overridesByKey.get(r.accountId + '|' + r.product2Id), r.asOf);
            if (ov != null) {
                res.finalPrice = ov.Override_Price__c;
                res.source = PriceSource.CUSTOMER_OVERRIDE;
                res.modifierId = ov.Id;
                results.add(res);
                continue;
            }

            // 6b) volume tier (segment-specific preferred over global)
            Price_Tier__c tier = pickActiveTier(tiersByProduct.get(r.product2Id), pbId, r.quantity, r.asOf);
            if (tier != null) {
                res.finalPrice = tier.Tier_Price__c;
                res.source = PriceSource.VOLUME_TIER;
                res.modifierId = tier.Id;
                results.add(res);
                continue;
            }

            // 6c) base segment price
            res.finalPrice = res.basePrice;
            res.source = PriceSource.BASE_PRICE;
            results.add(res);
        }
        return results;
    }

    /** Newest-effective active override for the date (null effective/end = open-ended). */
    private static Customer_Price__c pickActiveOverride(List<Customer_Price__c> candidates, Date asOf) {
        if (candidates == null) return null;
        Customer_Price__c best;
        for (Customer_Price__c cp : candidates) {
            if (!isActive(cp.Effective_Date__c, cp.End_Date__c, asOf)) continue;
            if (best == null || beats(cp.Effective_Date__c, best.Effective_Date__c)) best = cp;
        }
        return best;
    }

    /**
     * Active tier whose quantity range contains qty. Segment-specific tiers
     * (Pricebook2__c == pbId) win over global tiers (Pricebook2__c == null).
     */
    private static Price_Tier__c pickActiveTier(List<Price_Tier__c> candidates, Id pbId, Decimal qty, Date asOf) {
        if (candidates == null) return null;
        Price_Tier__c specific;
        Price_Tier__c globalTier;
        for (Price_Tier__c t : candidates) {
            if (!isActive(t.Effective_Date__c, t.End_Date__c, asOf)) continue;
            if (t.Min_Quantity__c != null && qty < t.Min_Quantity__c) continue;
            if (t.Max_Quantity__c != null && qty > t.Max_Quantity__c) continue;
            if (t.Pricebook2__c == pbId && t.Pricebook2__c != null) {
                if (specific == null || t.Min_Quantity__c > specific.Min_Quantity__c) specific = t;
            } else if (t.Pricebook2__c == null) {
                if (globalTier == null || t.Min_Quantity__c > globalTier.Min_Quantity__c) globalTier = t;
            }
        }
        return (specific != null) ? specific : globalTier;
    }

    private static Boolean isActive(Date effDate, Date endDate, Date asOf) {
        if (effDate != null && asOf < effDate) return false;
        if (endDate != null && asOf > endDate) return false;
        return true;
    }

    /** a beats b if a is later (later effective date wins; null effective = lowest priority). */
    private static Boolean beats(Date a, Date b) {
        if (a == null) return false;
        if (b == null) return true;
        return a > b;
    }
}
