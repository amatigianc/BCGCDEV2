@IsTest(isparallel=true)
public with sharing class LastLiveDateChatHandlerTest {
  @TestSetup
  static void makeData() {
    LeadTestFactory.createLead();

    ContactTestFactory.createContact();

    Campaign parentCampaign = new Campaign(
      Name = 'Parent',
      Type = 'webinar',
      StartDate = Date.today(),
      EndDate = Date.today().addYears(1),
      Status = 'In Progress'
    );
    insert parentCampaign;

    insert new Campaign(
      Name = 'Conversations from Drift 2024',
      Type = 'webinar',
      StartDate = Date.today(),
      EndDate = Date.today().addYears(1),
      Status = 'In Progress',
      Campaign_Offer_Type__c = 'Direct Response (Conversation)',
      ParentId = parentCampaign.Id
    );
  }

  @IsTest
  static void testFromSetLastLiveChatDate() {
    Lead lead = [
      SELECT Id, Last_Live_Chat_Date__c
      FROM Lead
      WHERE Email = 'LeadTestFactory@example.com'
      LIMIT 1
    ];
    lead.Last_Live_Chat_Date__c = Datetime.now();

    Contact contact = [
      SELECT Id, Last_Live_Chat_Date__c
      FROM Contact
      WHERE LastName LIKE 'ContactTestFactory%'
      LIMIT 1
    ];
    contact.Last_Live_Chat_Date__c = Datetime.now().addDays(-1);

    Campaign campaign = [
      SELECT Id
      FROM Campaign
      WHERE
        Name LIKE 'Conversations from Drift%'
        AND Status = 'In Progress'
        AND Campaign_Offer_Type__c = :Label.Campaign_Offer_Type_Direct_Response
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    insert new List<CampaignMember>{
      new CampaignMember(LeadId = lead.Id, CampaignId = campaign.Id),
      new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id)
    };

    Test.startTest();
    update lead;
    update contact;
    Test.stopTest();

    List<CampaignMember> members = [
      SELECT
        LeadId,
        Lead.Last_Live_Chat_Date__c,
        ContactId,
        Contact.Last_Live_Chat_Date__c,
        Response_Date__c
      FROM CampaignMember
      WHERE
        Campaign.Campaign_Offer_Type__c = :Label.Campaign_Offer_Type_Direct_Response
        AND Campaign.Status = 'In Progress'
        AND Campaign.ParentId != NULL
        AND Campaign.Name = 'Conversations from Drift 2024'
        AND (ContactId = :contact.Id
        OR LeadId = :lead.Id)
    ];

    System.assertEquals(
      2,
      members.size(),
      'Incorrect number of Campaign Member records.'
    );

    for (CampaignMember member : members) {
      Date expected = member.LeadId != null
        ? lead.Last_Live_Chat_Date__c.date()
        : contact.Last_Live_Chat_Date__c.date();
      System.assertEquals(
        expected,
        member.Response_Date__c,
        'Response_Date__c not set.'
      );
    }
  }

  @IsTest
  static void testNewCampaignMember() {
    Lead lead = [
      SELECT Id, Last_Live_Chat_Date__c
      FROM Lead
      WHERE Email = 'LeadTestFactory@example.com'
      LIMIT 1
    ];
    lead.Last_Live_Chat_Date__c = Date.today();
    update lead;

    Contact contact = [
      SELECT Id, Last_Live_Chat_Date__C
      FROM Contact
      WHERE LastName LIKE 'ContactTestFactory%'
      LIMIT 1
    ];
    contact.Last_Live_Chat_Date__c = Date.today().addDays(-1);
    update contact;

    Test.startTest();

    Campaign campaign = [
      SELECT Id
      FROM Campaign
      WHERE
        Status = 'In Progress'
        AND Campaign_Offer_Type__c = :Label.Campaign_Offer_Type_Direct_Response
        AND ParentId != NULL
        AND Name LIKE 'Conversations from Drift%'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    List<CampaignMember> members = new List<CampaignMember>{
      new CampaignMember(LeadId = lead.Id, CampaignId = campaign.Id),
      new CampaignMember(ContactId = contact.Id, CampaignId = campaign.Id)
    };
    insert members;

    Test.stopTest();

    members = [
      SELECT
        Id,
        LeadId,
        ContactId,
        Lead.Last_Live_Chat_Date__c,
        Contact.Last_Live_Chat_Date__c,
        Response_Date__c
      FROM CampaignMember
      WHERE Id IN :members
    ];
    for (CampaignMember member : members) {
      Date expected = member.LeadId != null
        ? member.Lead.Last_Live_Chat_Date__c.date()
        : member.Contact.Last_Live_Chat_Date__c.date();
      Date actual = member.Response_Date__c;

      System.assertEquals(expected, actual, 'Response Date not correctly set.');
    }
  }
}