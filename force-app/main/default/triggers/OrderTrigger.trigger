trigger OrderTrigger on Order (after undelete) {
	OrderTriggerHelper.afterUndelete(Trigger.new);
}