trigger Order on Order (before update, after update) {
    OrderTriggerHandler.handleTrigger(trigger.new, trigger.old, trigger.operationType);
}