@isTest(isparallel=true)
public class PostChatRatingTest {
  @isTest
  static void testPostChat() {
    Contact contact = ContactTestFactory.getContact();
    contact.FirstName = 'TestName';
    contact.LastName = 'TestLastName';
    contact.Phone = '415.555.1212';
    contact.Email = 'Gamati@brightcove.com';
    insert contact;
    Id personContact = [
      SELECT Id, Name
      FROM Contact
      WHERE Contact.Name = 'TestName TestLastName'
    ]
    .Id;

    Case case1 = new Case();
    case1.ContactId = personContact;
    case1.Type = 'Customer Support Cases';
    case1.Origin = 'Live Chat';
    case1.Status = 'Status example';
    insert case1;
    Case[] case2;
    case2 = [
      SELECT
        ContactId,
        Contact.Name,
        Id,
        AccountId,
        Status,
        Account.Name,
        Account_Account_ID__c,
        OwnerId,
        Zapier_Case_Owner__c,
        CaseNumber,
        CreatedDate,
        ClosedDate,
        Account_Tier__c,
        Support_Package__c,
        Origin,
        ContactEmail,
        Account_Edition__c
      FROM Case
      WHERE ContactId = :personContact
      ORDER BY CaseNumber DESC
      LIMIT 1
    ];

    if (case2.size() != 0) {
      case2[0].Origin = 'Live Chat';
      update case2;
    }

    PostChatRating postChat = new PostChatRating();
    postChat.getCase();
  }

  @isTest
  static void testErrorChat() {
    Contact contact = ContactTestFactory.getContact();
    contact.FirstName = 'TestName';
    contact.LastName = 'TestLastName';
    contact.Phone = '415.555.1212';
    contact.Email = 'Gamati@brightcove.com';

    insert contact;
    Id personContact = [
      SELECT Id, Name
      FROM Contact
      WHERE Contact.Name = 'TestName TestLastName'
    ]
    .Id;

    Case case1 = new Case();
    case1.ContactId = personContact;
    case1.Type = 'Customer Support Cases';
    case1.Origin = 'Live Chat';
    case1.Status = 'Status example';
    insert case1;
    Case[] case2;
    case2 = [
      SELECT
        ContactId,
        Contact.Name,
        Id,
        AccountId,
        Status,
        Account.Name,
        Account_Account_ID__c,
        OwnerId,
        Zapier_Case_Owner__c,
        CaseNumber,
        CreatedDate,
        ClosedDate,
        Account_Tier__c,
        Support_Package__c,
        Origin,
        ContactEmail,
        Account_Edition__c
      FROM Case
      WHERE ContactId = :personContact
      ORDER BY CaseNumber DESC
      LIMIT 1
    ];

    PostChatRating postChat = new PostChatRating();
    postChat.getCase();
  }
}