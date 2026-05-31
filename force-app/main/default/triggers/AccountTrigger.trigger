/**
 * AccountTrigger — single trigger per object, delegating to AccountTriggerHandler (P2-1 handler pattern).
 */
trigger AccountTrigger on Account (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.assignBranchOwnership(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.captureCreditHistory(Trigger.new, Trigger.oldMap);
    }
}
