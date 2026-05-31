/**
 * OrderTrigger — single trigger per object, delegates to OrderTriggerHandler (P2-1).
 */
trigger OrderTrigger on Order (before insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        OrderTriggerHandler.initializeLifecycle(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        OrderTriggerHandler.publishApprovalEvents(Trigger.new, Trigger.oldMap);
    }
}
