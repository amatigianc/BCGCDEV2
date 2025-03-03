@isTest
public with sharing class OpportunityTestFactory {
  static Id newBusinessRecordTypeId = RecordTypeUtility.getId(
    Opportunity.getSObjectType(),
    'New Business'
  );
  static Id leadRecordTypeId = RecordTypeUtility.getId(
    Opportunity.getSObjectType(),
    'Lead'
  );

  public static List<SObject> initOpp() {
    Account account = AccountTestFactory.getCustomer();

    String contactGuid = GuidUtility.generateGuid();
    Contact contact = new Contact(
      LastName = 'getStage1Opp',
      Email = contactGuid + '@example.com',
      Account = new Account(GUID__c = account.GUID__c),
      GUID__c = contactGuid
    );
    Opportunity opp = getStubInitOpp(contact);
    OpportunityContactRole contactRole = new OpportunityContactRole(
      Opportunity = new Opportunity(GUID__c = opp.GUID__c),
      Contact = new Contact(GUID__c = contact.GUID__c)
    );

    return new List<SObject>{ account, contact, opp, contactRole };
  }

  public static List<Opportunity> getStageZeroOpps(Integer count) {
    List<Account> accounts = AccountTestFactory.createCustomers(count);

    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < count; i++) {
      contacts.add(
        new Contact(
          LastName = 'getStageZeroOpps' + String.valueOf(i),
          Email = 'getStageZeroOpps' + String.valueOf(i) + '@example.com',
          AccountId = accounts[i].Id
        )
      );
    }
    insert contacts;

    List<Opportunity> opps = new List<Opportunity>();
    for (Integer i = 0; i < count; i++) {
      Opportunity stubOpp = getStageZeroStubOpp();
      stubOpp.AccountId = accounts[i].Id;
      stubOpp.ContactId = contacts[i].Id;
      opps.add(stubOpp);
    }
    return opps;
  }

  public static Opportunity getStageZeroOpp() {
    return getStageZeroOpps(1)[0];
  }

  public static Opportunity getStageZeroStubOpp() {
    return new Opportunity(
      Name = 'Irrelevant',
      RecordTypeId = leadRecordTypeId,
      StageName = '0 - Meeting Pending',
      CloseDate = Date.today().addDays(30),
      Forecast__c = 'Omitted',
      Contract_Type__c = 'Standard Term Contract',
      Deal_Type__c = 'New Business'
    );
  }

  public static void disqualifyStageZeroOpp(Opportunity opp) {
    opp.StageName = '0 - Disqualified';
    opp.Qualified_Out_Reason__c = Opportunity.Qualified_Out_Reason__c.getDescribe()
        .getPicklistValues()[0]
      .getValue();
  }

  public static void setStage2(Opportunity opp) {
    QuoteTestFactory.createPrimaryQuote(opp.Id);
    opp.Customer_Business_Model__c = 'N/A';
    opp.Targeted_Platforms__c = 'Other';
    opp.Competitors__c = 'Other';
    opp.Importance_and_Priority__c = 'N/A';
    opp.StageName = '2 - Demo';
  }

  public static void setStage3(Opportunity opp) {
    opp.Addressable_Business_Problems__c = 'N/A';
    opp.Customer_Expected_Outcomes__c = 'N/A';
    opp.Integrations_Required__c = 'N/A';
    opp.Sales_Strategy_to_Win__c = 'N/A';
    opp.Value_Proposition__c = 'N/A';
    opp.Budget_Source__c = 'N/A';
    opp.StageName = '3 - Solution Design & Evaluation';
  }

  public static void setStage4(Opportunity opp) {
    opp.Customer_Buying_Steps__c = 'N/A';
    opp.Mutual_Action_Plan__c = 'N/A';
    opp.Proposal_Document__c = 'http://example.com';
    opp.Solution_Document__c = 'http://example.com';
    opp.Technical_Win__c = true;
    opp.Customer_Success_KPIs__c = 'N/A';
    opp.StageName = '4 - Negotiation';
  }

  public static Opportunity getStage1Opp(Id accountId, Id recordTypeId) {
    Contact contact = new Contact(
      LastName = 'getStage1Opp',
      Email = GuidUtility.generateGuid() + '@example.com',
      AccountId = accountId,
      Guid__c = GuidUtility.generateGuid()
    );
    insert contact;
    return getStubOpp(contact, recordTypeId);
  }

  public static Opportunity getStage2Opp(Id accountId, Id recordTypeId) {
    Opportunity opp = getStage1Opp(accountId, recordTypeId);
    insert opp;
    setStage2(opp);
    return opp;
  }

  public static Opportunity getStage3Opp(Id accountId, Id recordTypeId) {
    Opportunity opp = getStage2Opp(accountId, recordTypeId);
    setStage3(opp);
    return opp;
  }

  public static Opportunity getStage4Opp(Id accountId, Id recordTypeId) {
    Opportunity opp = getStage3Opp(accountId, recordTypeId);
    setStage4(opp);
    return opp;
  }

  public static Opportunity getStage1Opp(Id accountId) {
    return getStage1Opp(accountId, newBusinessRecordTypeId);
  }

  public static Opportunity getStage2Opp(Id accountId) {
    return getStage2Opp(accountId, newBusinessRecordTypeId);
  }

  public static Opportunity getStage3Opp(Id accountId) {
    return getStage3Opp(accountId, newBusinessRecordTypeId);
  }

  public static Opportunity getStage4Opp(Id accountId) {
    return getStage4Opp(accountId, newBusinessRecordTypeId);
  }

  public static void closeWin(Opportunity opp) {
    closeWin(opp, false);
  }

  public static void closeWin(Opportunity opp, Boolean enableCpq) {
    SBQQ.TriggerControl.disable();
    if (enableCpq) {
      SBQQ.TriggerControl.enable();
    }
    opp.StageName = 'Closed Won';
    opp.Contract_Id__c = '1234';
  }

  static Opportunity getStubOpp(Contact contact, Id recordTypeId) {
    return new Opportunity(
      Name = 'OpportunityStageAccountHandlerTest',
      AccountId = contact.AccountId,
      ContactId = contact.Id,
      StageName = '1 - Discovery',
      CloseDate = System.today(),
      LeadSource = 'Other',
      RecordTypeId = recordTypeId,
      Solution_Document__c = 'http://www.google.com',
      Anticipated_Roadblocks_Challenges__c = 'OpportunityTestFactory',
      Invoice_Email_s__c = 'OpportunityTestFactory@OpportunityTestFactory.com',
      Contract_Type__c = 'Standard Term Contract',
      Notes_reason_win_loss__c = 'N/A',
      Reason_for_Win_Loss__c = 'Strong Relationship',
      SubReason_for_winloss__c = 'Product',
      Contract_Id__c = 'TEST-123456'
    );
  }

  static Opportunity getStubInitOpp(Contact contact) {
    return new Opportunity(
      Name = 'OpportunityStageAccountHandlerTest',
      Account = new Account(GUID__c = contact.Account.GUID__c),
      StageName = '1 - Discovery',
      CloseDate = System.today(),
      LeadSource = 'Other',
      RecordTypeId = newBusinessRecordTypeId,
      Solution_Document__c = 'http://www.google.com',
      Anticipated_Roadblocks_Challenges__c = 'OpportunityTestFactory',
      Invoice_Email_s__c = 'OpportunityTestFactory@OpportunityTestFactory.com',
      Contract_Type__c = 'Standard Term Contract',
      Notes_reason_win_loss__c = 'N/A',
      Reason_for_Win_Loss__c = 'Strong Relationship',
      SubReason_for_winloss__c = 'Product',
      Contract_Id__c = 'TEST-123456',
      GUID__c = GuidUtility.generateGuid()
    );
  }
}