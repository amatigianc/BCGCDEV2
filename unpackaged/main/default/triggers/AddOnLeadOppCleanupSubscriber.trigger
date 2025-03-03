trigger AddOnLeadOppCleanupSubscriber on Add_On_Lead_Opp_Cleanup__e (after insert) {
    AddOnLeadOppCleanupHandler.process(Trigger.new);
}