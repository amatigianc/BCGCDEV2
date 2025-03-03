public with sharing class ClientTerminationController {
  private Map<String, String> availableBCAccountsMap;
  private Map<String, String> selectedBCAccountsMap;
  private Map<String, String> availableContractsMap;
  private Map<String, String> selectedContractsMap;

  public Opportunity opp { get; set; }
  public Boolean confirmMode { get; set; }
  public String parentURL { get; set; }
  public String accountOwnerName { get; set; }
  public String accountManagerName { get; set; }
  public Boolean closeWindow { get; set; }
  public String title { get; set; }
  public String contactInformation { get; set; }
  public List<String> selectedBCAccountIds { get; set; }
  public List<String> removedBCAccountIds { get; set; }
  public List<String> selectedContractIds { get; set; }
  public List<String> removedContractIds { get; set; }

  public Map<String, String> getAvailableContractsMap() {
    return availableContractsMap;
  }

  public Map<String, String> getAvailableBCAccountsMap() {
    return availableBCAccountsMap;
  }

  public ClientTerminationController(
    ApexPages.StandardController stdController
  ) {
    initializeController();
  }

  public void initializeController() {
    contactInformation = '';
    title = 'Client Termination Request';
    closeWindow = false;
    String tempUrl = ApexPages.currentPage().getParameters().get('parenturl');
    parentURL = '';
    if (!String.isEmpty(tempUrl)) {
      parentURL = EncodingUtil.urlDecode(tempUrl, 'UTF-8');
    }
    confirmMode = false;
    Id oppId = ApexPages.currentPage().getParameters().get('oppId');
    opp = [
      SELECT
        Id,
        Name,
        StageName,
        Existing_MRR__c,
        AccountId,
        Owner.Name,
        Account.Owner.Name,
        CloseDate,
        Account.Name,
        Termination_Type__c,
        Request_Narrative_for_Finance_Review__c,
        Client_Termination_Rights__c,
        SubReason_for_winloss__c,
        Reason_for_Win_Loss__c,
        Client_Termination_Date__c,
        Deactivation_Date__c,
        Effective_Date__c,
        Contract_URL__c,
        Won_Lost_Against__c,
        Won_Lost_Story__c
      FROM Opportunity
      WHERE Id = :oppId
    ];

    Account account = [
      SELECT
        Id,
        Name,
        OwnerId,
        Owner.Name,
        (
          SELECT Id, User.Name
          FROM AccountTeamMembers
          WHERE TeamMemberRole = 'Account Manager'
        )
      FROM Account
      WHERE Id = :opp.AccountId
    ];

    accountOwnerName = account.AccountTeamMembers.isEmpty()
      ? account.Owner.Name
      : account.AccountTeamMembers[0].User.Name;

    initializeCollections();
    getBCAccounts();
    getContracts();
  }

  public PageReference cancel() {
    return new PageReference('/' + opp.Id);
  }

  public PageReference saveClientTermination() {
    confirmMode = false;
    String tempStr = '';

    if (selectedBCAccountsMap.keySet().isEmpty()) {
      tempStr = 'Select BC Accounts for termination';
    }

    if (!String.isEmpty(tempStr)) {
      Exception expObj = new BaseException(tempStr);
      expObj.setMessage(tempStr);
      ApexPages.addMessages(expObj);
      return null;
    }

    try {
      String bcAccountIds = '';
      for (String tempBcId : selectedBCAccountsMap.values()) {
        bcAccountIds += (!String.isEmpty(bcAccountIds))
          ? ';' + tempBcId
          : tempBcId;
      }

      String contractIds = '';
      String contractNames = '';
      for (String tempContractId : selectedContractsMap.keySet()) {
        contractIds += (!String.isEmpty(contractIds))
          ? ';' + tempContractId
          : tempContractId;
        String tempName = selectedContractsMap.get(tempContractId);
        contractNames += (!String.isEmpty(contractNames))
          ? ';' + tempName
          : tempName;
      }

      Opportunity updateOpp = new Opportunity(
        Id = opp.Id,
        Brightcove_Accounts_to_Terminate__c = bcAccountIds,
        Contracts_to_Terminate__c = contractNames,
        Contract_Ids_to_Terminate__c = contractIds,
        Client_Termination_Submitted__c = true,
        Client_Termination_Status__c = 'In Process',
        Client_Termination_Date_Stamp__c = Datetime.now(),
        Request_Narrative_for_Finance_Review__c = opp.Request_Narrative_for_Finance_Review__c,
        Client_Termination_Date__c = opp.Client_Termination_Date__c,
        Client_Termination_Rights__c = opp.Client_Termination_Rights__c,
        Effective_Date__c = opp.Effective_Date__c,
        Deactivation_Date__c = opp.Deactivation_Date__c,
        Contract_URL__c = opp.Contract_URL__c
      );

      update updateOpp;

      // Create an approval request for the account
      Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
      req.setComments('Client Termination Request');
      req.setObjectId(opp.id);

      // Client Termination Request
      Approval.ProcessResult result = Approval.process(req);
    } catch (Exception exp) {
      ApexPages.addMessages(exp);
      return null;
    }
    confirmMode = true;
    return new Pagereference('/' + opp.Id);
  }

  public void initializeCollections() {
    selectedBCAccountIds = new List<String>();
    removedBCAccountIds = new List<String>();
    availableBCAccountsMap = new Map<String, String>();
    selectedBCAccountsMap = new Map<String, String>();

    selectedContractIds = new List<String>();
    removedContractIds = new List<String>();
    availableContractsMap = new Map<String, String>();
    selectedContractsMap = new Map<String, String>();
  }

  public void getBCAccounts() {
    List<Brightcove_Account__c> brightCoveAccounts = [
      SELECT Id, Name, Brightcove_Account_Id__c
      FROM Brightcove_Account__c
      WHERE Account__c = :opp.AccountId
    ];
    for (Brightcove_Account__c brightCoveAccount : brightCoveAccounts) {
      availableBCAccountsMap.put(
        brightcoveAccount.Name,
        brightcoveAccount.Brightcove_Account_Id__c
      );
    }
  }

  public void getContracts() {
    List<Contract> contracts = [
      SELECT Id, Name, AccountId, ContractNumber
      FROM Contract
      WHERE AccountId = :opp.AccountId
    ];
    for (Contract contract : contracts) {
      availableContractsMap.put(contract.Id, contract.ContractNumber);
    }
  }

  public void add() {
    if (!selectedBCAccountIds.isEmpty()) {
      for (String bcAccountId : selectedBCAccountIds) {
        selectedBCAccountsMap.put(
          bcAccountId,
          availableBCAccountsMap.get(bcAccountId)
        );
        availableBCAccountsMap.remove(bcAccountId);
      }
    }
  }

  public void addContracts() {
    if (!selectedContractIds.isEmpty()) {
      for (String contractId : selectedContractIds) {
        selectedContractsMap.put(
          contractId,
          availableContractsMap.get(contractId)
        );
        availableContractsMap.remove(contractId);
      }
    }
  }

  public void remove() {
    if (!removedBCAccountIds.isEmpty()) {
      for (String bcAccountId : removedBCAccountIds) {
        availableBCAccountsMap.put(
          bcAccountId,
          selectedBCAccountsMap.get(bcAccountId)
        );
        selectedBCAccountsMap.remove(bcAccountId);
      }
    }
  }

  public void removeContracts() {
    if (!removedContractIds.isEmpty()) {
      for (String contractId : removedContractIds) {
        availableContractsMap.put(
          contractId,
          selectedContractsMap.get(contractId)
        );
        selectedContractsMap.remove(contractId);
      }
    }
  }

  public List<SelectOption> getAvailableBCAccounts() {
    List<SelectOption> availableBCAccounts = new List<SelectOption>();
    for (String bcAccountId : availableBCAccountsMap.keySet()) {
      availableBCAccounts.add(
        new SelectOption(bcAccountId, availableBCAccountsMap.get(bcAccountId))
      );
    }
    return availableBCAccounts;
  }

  public List<SelectOption> getAvailableContracts() {
    List<SelectOption> availableContracts = new List<SelectOption>();
    for (String contractId : availableContractsMap.keySet()) {
      String temp = availableContractsMap.get(contractId);
      if (!String.isEmpty(temp)) {
        availableContracts.add(new SelectOption(contractId, temp));
      }
    }
    return availableContracts;
  }

  public List<SelectOption> getSelectedBCAccounts() {
    List<SelectOption> selectedBCAccounts = new List<SelectOption>();
    for (String bcAccountId : selectedBCAccountsMap.keySet()) {
      selectedBCAccounts.add(
        new SelectOption(bcAccountId, selectedBCAccountsMap.get(bcAccountId))
      );
    }
    return selectedBCAccounts;
  }

  public List<SelectOption> getSelectedContracts() {
    List<SelectOption> selectedContracts = new List<SelectOption>();
    for (String contractId : selectedContractsMap.keySet()) {
      selectedContracts.add(
        new SelectOption(contractId, selectedContractsMap.get(contractId))
      );
    }
    return selectedContracts;
  }

  public class BaseException extends Exception {
  }
}