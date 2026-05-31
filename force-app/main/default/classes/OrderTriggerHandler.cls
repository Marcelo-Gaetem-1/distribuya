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

    /**
     * After update: when Credit_Status__c transitions to 'Approved', publish an
     * Order_Approved__e platform event so downstream integration (Phase 4 — ERP,
     * logistics) can react asynchronously without coupling to the order transaction.
     * Bulk-safe: collects events and publishes once via EventBus.publish.
     */
    public static void publishApprovalEvents(List<Order> newOrders, Map<Id, Order> oldMap) {
        List<Order_Approved__e> events = new List<Order_Approved__e>();
        for (Order o : newOrders) {
            Order oldO = oldMap.get(o.Id);
            Boolean justApproved = o.Credit_Status__c == 'Approved' && oldO.Credit_Status__c != 'Approved';
            if (justApproved) {
                events.add(new Order_Approved__e(
                    Order_Id__c = o.Id,
                    Order_Number__c = o.OrderNumber,
                    Account_Id__c = o.AccountId,
                    Total_Amount__c = o.TotalAmount
                ));
            }
        }
        if (!events.isEmpty()) EventBus.publish(events);
    }
}
