trigger OpportunityPartnerChangeSubscriber on Opportunity_Partner_Change__e(
    after insert
) {
    OpportunityPartnerChangeHandler.processEvents(Trigger.new);
}