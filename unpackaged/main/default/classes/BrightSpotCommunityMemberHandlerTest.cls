@isTest(isparallel=true)
public with sharing class BrightSpotCommunityMemberHandlerTest {
  @TestSetup
  private static void makeData() {
    ContactTestFactory.createContact();

    Campaign theBrightSpotCampaign = new Campaign(
      Name = 'Community - The Bright Spot Registration - 012024'
    );

    insert theBrightSpotCampaign;
  }

  @isTest
  private static void testCreateCommunity() {
    List<Contact> testContactRecords = [
      SELECT Id
      FROM CONTACT
      WHERE LastName LIKE 'ContactTestFactory%'
    ];

    Id communityCampaignId = [
      SELECT Id
      FROM Campaign
      WHERE Name = 'Community - The Bright Spot Registration - 012024'
    ]
    .Id;

    User apiUser = [SELECT Id FROM User WHERE Name = 'API Integration User'];

    List<Community_Member__c> newBrightSpotMembers = new List<Community_Member__c>();

    System.runAs(apiUser) {
      for (Contact contactRecord : testContactRecords) {
        Community_Member__c theBrightSpotMember = new Community_Member__c(
          Name = 'theBrightSpot',
          Contact__c = contactRecord.Id,
          Registration_date__c = Date.Today(),
          UserId__c = '123456'
        );
        newBrightSpotMembers.add(theBrightSpotMember);
      }
      insert newBrightSpotMembers;
    }

    List<CampaignMember> newCampaignMembers = [
      SELECT Id, CampaignId
      FROM CampaignMember
      WHERE ContactId IN :testContactRecords
    ];
    System.assert(
      newCampaignMembers.size() > 0,
      'No campaign members have been created'
    );
    for (CampaignMember campaignMemberRecord : newCampaignMembers) {
      system.assertEquals(
        communityCampaignId,
        campaignMemberRecord.CampaignId,
        'Community Members not added to the correct Campaign'
      );
    }
  }
}