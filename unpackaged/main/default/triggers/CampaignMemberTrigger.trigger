trigger CampaignMemberTrigger on CampaignMember(before insert) {
    new DomainHandlerUtility().process();
}