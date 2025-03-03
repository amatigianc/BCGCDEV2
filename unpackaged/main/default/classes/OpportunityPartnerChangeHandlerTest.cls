@isTest
public with sharing class OpportunityPartnerChangeHandlerTest {
  @TestSetup
  static void makeData() {
    List<Account> customerAccounts = AccountTestFactory.getCustomers(2);
    customerAccounts[0].Name = 'Customer 1';
    customerAccounts[1].Name = 'Customer 2';
    insert customerAccounts;

    List<Account> partnerAccounts = AccountTestFactory.createPartners(2);

    List<Opportunity> opps = new List<Opportunity>{
      OpportunityTestFactory.getStage1Opp(customerAccounts[0].Id),
      OpportunityTestFactory.getStage1Opp(customerAccounts[1].Id),
      OpportunityTestFactory.getStage1Opp(customerAccounts[1].Id)
    };
    opps[0].Partner__c = partnerAccounts[0].Id;
    opps[0].Partner_Type__c = 'Transactional';

    opps[1].Partner__c = partnerAccounts[0].Id;
    opps[1].Partner_Type__c = 'Technical';

    opps[2].Partner__c = partnerAccounts[0].Id;
    opps[2].Partner_Type__c = 'Technical';
    insert opps;
  }

  @isTest
  static void testRelationshipCleanup() {
    List<Account> partners = [
      SELECT Id, Name
      FROM Account
      WHERE RecordType.Name = 'Partner'
      ORDER BY Name
    ];

    List<Partner_Relationship__c> relationships = [
      SELECT Id, Customer_Account__c, Partner_Account__c, Type__c
      FROM Partner_Relationship__c
    ];

    //System.assert(!relationships.isEmpty(), 'No existing relationships exist.');

    List<Opportunity> opps = [
      SELECT Id, AccountId, Partner__c, Partner_Type__c
      FROM Opportunity
      WHERE Partner__c != NULL
      ORDER BY Account.Name
    ];

    // This Opportunity will validate the removal of a deprecated
    // Partner Relationship record.
    opps[0].Partner__c = partners[1].Id;

    // This Opportunity will validate the persistence of a
    // Partner Relationship record due to an existing Opportunity
    opps[1].Partner__c = partners[1].Id;

    Test.startTest();
    update opps;
    Test.getEventBus().deliver();
    Test.stopTest();

    relationships = [
      SELECT
        Id,
        Customer_Account__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        Type__c
      FROM Partner_Relationship__c
      WHERE Customer_Account__r.Name IN ('Customer 1', 'Customer 2')
      ORDER BY Customer_Account__r.Name
    ];

    List<Account> customers = [
      SELECT
        Id,
        Name,
        (
          SELECT Id, Partner_Account__r.Name, Type__c
          FROM Partner_Relationships__r
          ORDER BY Partner_Account__r.Name
        )
      FROM Account
      WHERE Name IN ('Customer 1', 'Customer 2')
    ];

    for (Account customer : customers) {
      if (customer.Name == 'Customer 1') {
        System.assertEquals(
          1,
          customer.Partner_Relationships__r.size(),
          'Incorrect number of Partner Relationship records for ' +
          customer.Name
        );

        System.assertEquals(
          partners[1].Name,
          customer.Partner_Relationships__r[0].Partner_Account__r.Name,
          'Incorrect Partner Account on Partner Relationship record for ' +
          customer.Name
        );
      } else if (customer.Name == 'Customer 2') {
        System.assertEquals(
          2,
          customer.Partner_Relationships__r.size(),
          'Incorrect number of Partner Relationship records for ' +
          customer.Name
        );

        System.assertEquals(
          partners[0].Name,
          customer.Partner_Relationships__r[0].Partner_Account__r.Name,
          'Incorrect Partner Account on Partner Relationship record for ' +
          customer.Name
        );
        System.assertEquals(
          partners[1].Name,
          customer.Partner_Relationships__r[1].Partner_Account__r.Name,
          'Incorrect Partner Account on Partner Relationship record for ' +
          customer.Name
        );
      }
    }
  }
}