@isTest
public with sharing class QuoteContractIdHandlerTest {
  @TestSetup
  static void makeData() {
    Account accountNewBus = AccountTestFactory.getCustomer();
    accountNewBus.Name = 'BrightcoveOpportunityContractIdHandlerNewBus';

    Opportunity opp = OpportunityTestFactory.getStage1Opp(
      accountNewBus.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'New Business')
    );

    Account accountAddOn = AccountTestFactory.getCustomer();
    accountAddOn.Name = 'AddOnBrightcoveOpportunityContractIdHandler';

    Opportunity opp2 = OpportunityTestFactory.getStage1Opp(
      accountAddOn.Id,
      RecordTypeUtility.getId(Opportunity.getSObjectType(), 'Add-On')
    );

    List<Account> accounts = new List<Account>{ accountNewBus, accountAddOn };
    insert accounts;

    opp.AccountId = accountNewBus.Id;
    opp2.AccountId = accountAddOn.Id;

    List<Opportunity> opps = new List<Opportunity>{ opp, opp2 };
    insert opps;
  }

  @isTest
  static void testQuoteContractIdHandlerTestNewBus() {
    Opportunity opp = [
      SELECT Id, Account.Name
      FROM Opportunity
      WHERE Account.Name = 'BrightcoveOpportunityContractIdHandlerNewBus'
    ];

    SBQQ__Quote__c quoteinsert = QuoteTestFactory.createPrimaryQuote(opp.Id);

    quoteinsert = [
      SELECT Id, Name, CreatedDate
      FROM SBQQ__Quote__c
      WHERE Id = :quoteinsert.Id
    ];

    String accName = opp.Account.Name.left(6).trim();
    String quoteCreatedDate = quoteinsert.CreatedDate.format('MMddYY');
    String quotePrimaryQuote = quoteinsert.Name;

    String contractIdInsert =
      accName +
      '-' +
      quoteCreatedDate +
      '-' +
      quotePrimaryQuote;

    opp = [
      SELECT Id, Account.Name, Contract_Id__c
      FROM Opportunity
      WHERE Account.Name = 'BrightcoveOpportunityContractIdHandlerNewBus'
    ];

    System.assertEquals(
      contractIdInsert,
      opp.Contract_Id__c,
      'Contract Id was not updated on insert'
    );

    SBQQ__Quote__c quoteupdate = QuoteTestFactory.getBaseQuote();
    quoteupdate.SBQQ__Opportunity2__c = opp.Id;
    insert quoteupdate;

    Test.startTest();

    quoteupdate.SBQQ__Primary__c = true;
    update quoteupdate;

    Test.stopTest();

    quoteupdate = [
      SELECT Id, Name, CreatedDate
      FROM SBQQ__Quote__c
      WHERE Id = :quoteupdate.Id
    ];
    String accNameUpdate = opp.Account.Name.left(6).trim();
    String quoteCreatedDateUpdate = quoteupdate.CreatedDate.format('MMddYY');
    String quotePrimaryQuoteUpdate = quoteupdate.Name;

    String contractIdUpdate =
      accNameUpdate +
      '-' +
      quoteCreatedDateUpdate +
      '-' +
      quotePrimaryQuoteUpdate;

    opp = [
      SELECT Id, Account.Name, Contract_Id__c
      FROM Opportunity
      WHERE Account.Name = 'BrightcoveOpportunityContractIdHandlerNewBus'
    ];

    System.assertEquals(
      contractIdUpdate,
      opp.Contract_Id__c,
      'Contract Id was not updated on update'
    );
  }

  @isTest
  static void testQuoteContractIdHandlerTestAddOn() {
    Opportunity opp = [
      SELECT Id, Account.Name
      FROM Opportunity
      WHERE Account.Name = 'AddOnBrightcoveOpportunityContractIdHandler'
    ];

    SBQQ__Quote__c quoteinsert = QuoteTestFactory.createPrimaryQuote(opp.Id);

    quoteinsert = [
      SELECT Id, Name, CreatedDate
      FROM SBQQ__Quote__c
      WHERE Id = :quoteinsert.Id
    ];

    String accName = opp.Account.Name.left(6).trim();
    String quoteCreatedDate = quoteinsert.CreatedDate.format('MMddYY');
    String quotePrimaryQuote = quoteinsert.Name;

    String contractIdInsert =
      accName +
      '-' +
      quoteCreatedDate +
      '-' +
      quotePrimaryQuote;

    opp = [
      SELECT Id, Account.Name, Contract_Id__c
      FROM Opportunity
      WHERE Account.Name = 'AddOnBrightcoveOpportunityContractIdHandler'
    ];

    System.assertEquals(
      contractIdInsert,
      opp.Contract_Id__c,
      'Contract Id was not updated on insert'
    );

    SBQQ__Quote__c quoteupdate = QuoteTestFactory.getBaseQuote();
    quoteupdate.SBQQ__Opportunity2__c = opp.Id;
    insert quoteupdate;

    Test.startTest();

    quoteupdate.SBQQ__Primary__c = true;
    update quoteupdate;

    Test.stopTest();

    quoteupdate = [
      SELECT Id, Name, CreatedDate
      FROM SBQQ__Quote__c
      WHERE Id = :quoteupdate.Id
    ];
    String accNameUpdate = opp.Account.Name.left(6).trim();
    String quoteCreatedDateUpdate = quoteupdate.CreatedDate.format('MMddYY');
    String quotePrimaryQuoteUpdate = quoteupdate.Name;

    String contractIdUpdate =
      accNameUpdate +
      '-' +
      quoteCreatedDateUpdate +
      '-' +
      quotePrimaryQuoteUpdate;

    opp = [
      SELECT Id, Account.Name, Contract_Id__c
      FROM Opportunity
      WHERE Account.Name = 'AddOnBrightcoveOpportunityContractIdHandler'
    ];

    System.assertEquals(
      contractIdUpdate,
      opp.Contract_Id__c,
      'Contract Id was not updated on update'
    );
  }
}