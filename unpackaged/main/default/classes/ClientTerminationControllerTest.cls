@isTest
public with sharing class ClientTerminationControllerTest {
  @TestSetup
  static void makeData() {
    Account account = AccountTestFactory.createCustomer();

    Opportunity opp = OpportunityTestFactory.getStage4Opp(account.Id);
    opp.StageName = 'Closed Lost';
    update opp;

    insert new Brightcove_Account__c(
      Name = 'ClientTerminationControllerTest',
      Brightcove_Account_Id__c = '12345',
      Email_Address__c = 'brightcoveAccount@example.com',
      Account_Profile__c = 'Trial',
      Account__c = account.Id
    );

    insert new Contract(
      AccountId = account.Id,
      StartDate = System.today(),
      ContractTerm = 12
    );
  }

  @isTest
  static void testSaveClientTermination() {
    Opportunity opp = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    List<Brightcove_Account__c> brightcoveAccounts = [
      SELECT Id, Name, Brightcove_Account_Id__c
      FROM Brightcove_Account__c
      WHERE Account__c = :opp.AccountId
    ];

    List<Contract> contracts = [
      SELECT Id, ContractNumber
      FROM Contract
      WHERE AccountId = :opp.AccountId
    ];

    PageReference pageRef = Page.ClientTermination;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('oppId', opp.id);
    ClientTerminationController clientTermination = new ClientTerminationController(
      new ApexPages.standardController(opp)
    );

    ClientTermination.selectedBCAccountIds.add(brightcoveAccounts[0].Name);
    ClientTermination.add();

    ClientTermination.selectedContractIds.add(contracts[0].Id);
    ClientTermination.addContracts();

    Test.startTest();

    clientTermination.saveClientTermination();

    Test.stopTest();

    opp = [
      SELECT
        Id,
        Brightcove_Accounts_to_Terminate__c,
        Contracts_To_Terminate__c,
        Contract_Ids_To_Terminate__c,
        Client_Termination_Submitted__c,
        Client_Termination_Status__c,
        Client_Termination_Date_Stamp__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];

    System.assertEquals(
      brightcoveAccounts[0].Brightcove_Account_Id__c,
      opp.Brightcove_Accounts_to_Terminate__c,
      'Selected Brightcove Account Id not assigned to Opportunity.'
    );
    System.assertEquals(
      contracts[0].ContractNumber,
      opp.Contracts_to_Terminate__c,
      'Selected Contract Name not assigned to Opportunity.'
    );
    System.assertEquals(
      contracts[0].Id,
      opp.Contract_Ids_to_Terminate__c,
      'Selected Contract Id not assigned to Opportunity.'
    );
    System.assert(
      opp.Client_Termination_Submitted__c,
      'Client Termination Submitted flag not set.'
    );
    System.assertEquals(
      'In Process',
      opp.Client_Termination_Status__c,
      'Client Termination Status not set.'
    );
    System.assertEquals(
      Date.today(),
      opp.Client_Termination_Date_Stamp__c.date(),
      'Client Termination Date Stamp not set.'
    );
  }

  /**
   * I'm 99% sure that the "accountManagerName" variable isn't actually useful since it's never set,
   * and only used in the context of outputText in the VF Page, so this text is dumb, but grants a
   * sliver of coverage.
   */
  @isTest
  static void testAccountManagerName() {
    Opportunity opp = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    PageReference pageRef = Page.ClientTermination;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('oppId', opp.id);
    ClientTerminationController clientTermination = new ClientTerminationController(
      new ApexPages.standardController(opp)
    );

    String expected = 'A very good name';
    clientTermination.accountManagerName = expected;
    String actual = clientTermination.accountManagerName;
    System.assertEquals(
      expected,
      actual,
      'accountManagerName set/get not correct.'
    );
  }

  @isTest
  static void testBCAccounts() {
    Opportunity opp = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    List<Brightcove_Account__c> brightcoveAccounts = [
      SELECT Id, Name, Brightcove_Account_Id__c
      FROM Brightcove_Account__c
      WHERE Account__c = :opp.AccountId
    ];

    PageReference pageRef = Page.ClientTermination;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('oppId', opp.id);
    ClientTerminationController clientTermination = new ClientTerminationController(
      new ApexPages.standardController(opp)
    );

    ClientTermination.getBCAccounts();
    Map<String, String> availableBCAccountsMap = ClientTermination.getAvailableBCAccountsMap();
    for (Brightcove_Account__c brightcoveAccount : brightcoveAccounts) {
      System.assert(
        availableBCAccountsMap.containsKey(brightcoveAccount.Name),
        '"' + brightcoveAccount.Name + '" not found in Available BCAccounts Map'
      );
    }
  }

  @isTest
  static void testCancel() {
    Opportunity opp = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    PageReference pageRef = Page.ClientTermination;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('oppId', opp.id);
    ClientTerminationController clientTermination = new ClientTerminationController(
      new ApexPages.standardController(opp)
    );

    PageReference actual = ClientTermination.cancel();
    PageReference expected = new PageReference('/' + opp.Id);
    System.assertEquals(
      expected.getUrl(),
      actual.getUrl(),
      'Incorrect Page Reference returned.'
    );
  }

  @isTest
  static void testContracts() {
    Opportunity opp = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    PageReference pageRef = Page.ClientTermination;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('oppId', opp.id);
    ClientTerminationController clientTermination = new ClientTerminationController(
      new ApexPages.standardController(opp)
    );

    List<Contract> expectedContracts = [
      SELECT Id, ContractNumber
      FROM Contract
      WHERE AccountId = :opp.AccountId
    ];

    ClientTermination.getContracts();
    Map<String, String> availableContractsMap = ClientTermination.getAvailableContractsMap();
    for (Contract contract : expectedContracts) {
      System.assert(
        availableContractsMap.containsKey(contract.Id),
        'Contract missing from Available Contracts.'
      );
      System.assertEquals(
        contract.ContractNumber,
        availableContractsMap.get(contract.Id),
        'ContractNumber missing from Available Contracts.'
      );
    }

    ClientTermination.selectedContractIds.add(expectedContracts[0].Id);
    ClientTermination.addContracts();
    List<SelectOption> selectedContracts = ClientTermination.getSelectedContracts();
    System.assert(
      selectedContracts.contains(
        new SelectOption(
          expectedContracts[0].Id,
          expectedContracts[0].Contractnumber
        )
      ),
      '"' +
        expectedContracts[0].ContractNumber +
        '" Contract not added to Selected Contracts.'
    );
    availableContractsMap = ClientTermination.getAvailableContractsMap();
    System.assert(
      !availableContractsMap.containsKey(expectedContracts[0].Id),
      'Contract not removed from Available Contracts.'
    );

    ClientTermination.removedContractIds.add(expectedContracts[0].Id);
    ClientTermination.removeContracts();
    System.assert(
      !ClientTermination.getSelectedContracts()
        .contains(
          new SelectOption(
            expectedContracts[0].Id,
            expectedContracts[0].ContractNumber
          )
        ),
      'Contract Id not removed from selected Contracts.'
    );
  }

  @isTest
  static void testAddRemoveBrightcoveAccounts() {
    Opportunity opp = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Account.Name LIKE 'AccountTestFactory%' AND IsClosed = FALSE
      LIMIT 1
    ];

    PageReference pageRef = Page.ClientTermination;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('oppId', opp.id);
    ClientTerminationController clientTermination = new ClientTerminationController(
      new ApexPages.standardController(opp)
    );

    opp = ClientTermination.opp;
    opp.Client_Termination_Status__c = 'Yes';
    opp.Client_Termination_Date__c = Date.today();
    opp.DeActivation_Date__c = Date.today();
    opp.Effective_Date__c = Date.today();
    opp.Contract_URL__c = 'https://google.com';

    Map<String, String> availableBCAccountsMap = ClientTermination.getAvailableBCAccountsMap();
    List<Brightcove_Account__c> brightcoveAccounts = [
      SELECT Id, Name, Brightcove_Account_Id__c
      FROM Brightcove_Account__c
      WHERE Account__c = :opp.AccountId
    ];
    for (Brightcove_Account__c brightcoveAccount : brightcoveAccounts) {
      System.assert(
        availableBCAccountsMap.containsKey(brightcoveAccount.Name),
        '"' +
          brightcoveAccount.Name +
          '" Brightcove Account not returned in availableBCAccountsMap'
      );
      System.assertEquals(
        brightcoveAccount.Brightcove_Account_Id__c,
        availableBCAccountsMap.get(brightcoveAccount.Name),
        'Incorrect Brightcove Account Id for "' +
          brightcoveAccount.Name +
          '" Brightcove Account'
      );
    }

    ClientTermination.selectedBCAccountIds.add(
      brightcoveAccounts[0].Brightcove_Account_Id__c
    );
    ClientTermination.add();
    System.assert(
      ClientTermination.selectedBCAccountIds.contains(
        brightcoveAccounts[0].Brightcove_Account_Id__c
      ),
      '"' +
        brightcoveAccounts[0].Brightcove_Account_Id__c +
        '" Brightcove Account Id not added to selectedBCAccountIds'
    );

    ClientTermination.removedBCAccountIds.add(
      brightcoveAccounts[0].Brightcove_Account_Id__c
    );
    ClientTermination.remove();

    List<SelectOption> selectedBCAccountOptions = ClientTermination.getSelectedBCAccounts();
    List<String> selectedBCAccountValues = new List<String>();
    for (SelectOption option : selectedBCAccountOptions) {
      selectedBCAccountValues.add(option.getValue());
    }

    System.assert(
      !selectedBCAccountValues.contains(
        brightcoveAccounts[0].Brightcove_Account_Id__c
      ),
      '"' +
        brightcoveAccounts[0].Brightcove_Account_Id__c +
        '" Brightcove AccountId not removed from selected options.'
    );
  }
}