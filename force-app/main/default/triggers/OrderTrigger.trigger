/**
 * OrderTrigger — single trigger per object, delegates to OrderTriggerHandler (P2-1).
 */
trigger OrderTrigger on Order (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        OrderTriggerHandler.initializeLifecycle(Trigger.new);
    }
}
