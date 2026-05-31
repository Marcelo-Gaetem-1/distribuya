/**
 * OrderTriggerHandler — Order lifecycle initialization (Phase 2, step 5; ADR-0004).
 *
 * On insert, sets sensible lifecycle defaults so the three orthogonal status fields
 * (Credit/Fulfillment/Payment) start consistently, instead of relying on the picklist
 * defaults alone. Bulk-safe (P2-7); no SOQL/DML in loops.
 *
 * Initialization rule:
 *  - Fulfillment_Status__c  -> Not_Started (if blank)
 *  - Payment_Status__c      -> Not_Paid    (if blank)
 *  - Credit_Status__c       -> leave as provided; only default to Not_Required when blank.
 *    (Whether an order *needs* credit approval, i.e. flipping to Pending, is decided by the
 *    order-submission process, not on raw insert — keeps insert side-effect-free.)
 */
public with sharing class OrderTriggerHandler {

    public static void initializeLifecycle(List<Order> newOrders) {
        for (Order o : newOrders) {
            if (String.isBlank(o.Fulfillment_Status__c)) o.Fulfillment_Status__c = 'Not_Started';
            if (String.isBlank(o.Payment_Status__c))     o.Payment_Status__c = 'Not_Paid';
            if (String.isBlank(o.Credit_Status__c))       o.Credit_Status__c = 'Not_Required';
        }
    }
}
