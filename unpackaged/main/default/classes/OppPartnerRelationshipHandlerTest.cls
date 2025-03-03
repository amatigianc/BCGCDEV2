@isTest
public with sharing class OppPartnerRelationshipHandlerTest {
  @TestSetup
  static void testDataSetup() {
    AccountTestFactory.createPartners(3);
    AccountTestFactory.createCustomer();
  }

  @isTest
  static void testPartnerRelationship() {
    List<Account> accounts = [
      SELECT Id, Name
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
      ORDER BY RecordType.Name
    ];
    Account customer = accounts[0];
    Account partner1 = accounts[1];
    Account partner2 = accounts[2];
    Account partner3 = accounts[3];

    List<Opportunity> opps = new List<Opportunity>{
      OpportunityTestFactory.getStage1Opp(customer.Id),
      OpportunityTestFactory.getStage1Opp(customer.Id),
      OpportunityTestFactory.getStage1Opp(customer.Id),
      OpportunityTestFactory.getStage1Opp(customer.Id)
    };
    opps[0].Partner__c = partner1.Id;
    opps[0].Partner_Type__c = 'Transactional';

    opps[1].Partner__c = partner2.Id;
    opps[1].Partner_Type__c = 'Technical';

    opps[2].Partner__c = partner2.Id;
    opps[2].Partner_Type__c = 'Transactional';

    insert opps;

    Test.startTest();

    List<Partner_Relationship__c> relationships = [
      SELECT Id, Partner_Account__r.Name, Type__c
      FROM Partner_Relationship__c
      WHERE Customer_Account__c = :customer.Id
      ORDER BY Partner_Account__r.Name ASC, Type__c ASC
    ];

    System.assertEquals(
      3,
      relationships.size(),
      'Incorrect number of Partner Relationship records created.'
    );

    System.assertEquals(
      partner1.Name,
      relationships[0].Partner_Account__r.Name,
      'Incorrect Partner assigned to Partner Relationship record'
    );
    System.assertEquals(
      'Transactional',
      relationships[0].Type__c,
      'Incorrect Type assigned to Partner Relationship record: ' +
      relationships[0].Type__c
    );

    System.assertEquals(
      partner2.Name,
      relationships[1].Partner_Account__r.Name,
      'Incorrect Partner assigned to Partner Relationship record'
    );
    System.assertEquals(
      'Transactional',
      relationships[1].Type__c,
      'Incorrect Type assigned to Partner Relationship record: ' +
      relationships[1].Type__c
    );

    System.assertEquals(
      partner2.Name,
      relationships[2].Partner_Account__r.Name,
      'Incorrect Partner assigned to Partner Relationship record'
    );
    System.assertEquals(
      'Technical',
      relationships[2].Type__c,
      'Incorrect Type assigned to Partner Relationship record: ' +
      relationships[2].Type__c
    );

    opps[0].Partner__c = partner3.Id;
    opps[0].Partner_Type__c = 'Transactional';
    opps[1].Partner__c = partner2.Id;
    opps[1].Partner_Type__c = 'Technical';
    opps[3].Partner__c = partner2.Id;
    opps[3].Partner_Type__c = 'Transactional';

    update opps;

    Test.stopTest();

    relationships = [
      SELECT Id, Type__c, Partner_Account__r.Name
      FROM Partner_Relationship__c
      WHERE Customer_Account__c = :customer.Id
      ORDER BY Partner_Account__r.Name ASC, Type__c ASC
    ];

    System.assertEquals(
      3,
      relationships.size(),
      'Incorrect number of Partner Relationship records created.'
    );

    System.assertEquals(
      partner2.Name,
      relationships[0].Partner_Account__r.Name,
      'Incorrect Partner assigned to Partner Relationship record'
    );
    System.assertEquals(
      'Transactional',
      relationships[0].Type__c,
      'Incorrect Partner Type assigned to Partner Relationship record'
    );

    System.assertEquals(
      partner2.Name,
      relationships[1].Partner_Account__r.Name,
      'Incorrect Partner assigned to Partner Relationship record'
    );
    System.assertEquals(
      'Technical',
      relationships[1].Type__c,
      'Incorrect Partner Type assigned to Partner Relationship record'
    );

    System.assertEquals(
      partner3.Name,
      relationships[2].Partner_Account__r.Name,
      'Incorrect Partner assigned to Partner Relationship record'
    );
    System.assertEquals(
      'Transactional',
      relationships[2].Type__c,
      'Incorrect Partner Type assigned to Partner Relationship record'
    );
  }
}