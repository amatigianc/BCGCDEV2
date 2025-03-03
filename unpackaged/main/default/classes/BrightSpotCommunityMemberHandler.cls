public with sharing class BrightSpotCommunityMemberHandler extends DomainLogicHandler {
  private List<Community_Member__c> communityMemberList = new List<Community_Member__c>();

  public override void check(SObject newObj) {
    communityMemberList.add((Community_Member__c) newObj);
  }

  public override void processRecords() {
    Id campaignRecordId = [
      SELECT id
      FROM Campaign
      WHERE Name = 'Community - The Bright Spot Registration - 012024'
    ]
    .Id;

    List<CampaignMember> newcampaignMembersList = new List<CampaignMember>();

    for (Community_Member__c communityMemberRec : communityMemberList) {
      CampaignMember campaignMemberRecord = new CampaignMember();
      campaignMemberRecord.CampaignId = campaignRecordId;
      campaignMemberRecord.ContactId = communityMemberRec.Contact__c;
      campaignMemberRecord.Status = 'Responded';

      newcampaignMembersList.add(campaignMemberRecord);
    }
    try {
      insert newcampaignMembersList;
    } catch (DmlException e) {
      ExceptionHandler.process(e, 'BrightSpotCommunityMemberHandler');
    }
  }
}