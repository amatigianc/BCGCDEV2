@IsTest(isparallel=true)
private class AccountProductPlatformTest {
  @isTest
  static void testProcess() {
    Id accountId = insertAccount();
    insertProducts();
    insertContract(accountId);
    insertSubscriptions();

    Contract testContract = [
      SELECT Id, AccountId, Status
      FROM Contract
      WHERE Name = 'testContract'
    ];

    Test.startTest();
    testContract.Status = 'Activated';

    update testContract;

    Test.getEventBus().deliver();
    Test.stopTest();

    List<Account_Product__c> accountProducts = [
      SELECT
        Id,
        Product_Name__c,
        Start_Date__c,
        End_Date__c,
        Contract_Id__c,
        Account__c,
        Product_Description__c
      FROM Account_Product__c
      WHERE Account__r.name LIKE 'AccountTestFactory%'
      ORDER BY Product_Name__c ASC
    ];

    List<SBQQ__Subscription__c> subscriptions = [
      SELECT
        Id,
        SBQQ__ProductName__c,
        SBQQ__StartDate__c,
        SBQQ__EndDate__c,
        SBQQ__Contract__c,
        SBQQ__Account__c,
        SBQQ__PackageProductDescription__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Contract_Id__c
      FROM SBQQ__Subscription__c
      WHERE SBQQ__Account__r.Name LIKE 'AccountTestFactory%'
      ORDER BY SBQQ__ProductName__c ASC
    ];

    System.assertEquals(
      accountProducts.size(),
      subscriptions.size(),
      'ERROR: not all the replicas match the subscriptions'
    );

    for (Integer i = 0; i < accountProducts.size(); i++) {
      System.assertEquals(
        accountProducts[i].Product_Name__c,
        subscriptions[i].SBQQ__ProductName__c,
        'ERROR: Product Name mismatch'
      );

      System.assertEquals(
        subscriptions[i]
          .SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Contract_Id__c,
        accountProducts[i].Contract_Id__c,
        'ERRRO: Contract Id not matching'
      );

      System.assertEquals(
        subscriptions[i].SBQQ__PackageProductDescription__c,
        accountProducts[i].Product_Description__c,
        'ERRRO: Product Description not matching'
      );

      System.assertEquals(
        accountProducts[i].Start_Date__c,
        subscriptions[i].SBQQ__StartDate__c,
        'ERROR: Start Date not matching'
      );
      System.assertEquals(
        accountProducts[i].End_Date__c,
        subscriptions[i].SBQQ__EndDate__c,
        'ERROR: End Date not matching'
      );
      System.assertEquals(
        accountProducts[i].Account__c,
        subscriptions[i].SBQQ__Account__c,
        'ERROR: AccountId not matching'
      );
    }
  }

  static private Id insertAccount() {
    Account account = AccountTestFactory.createCustomer();

    SBQQ.TriggerControl.disable();

    return account.Id;
  }

  static private void insertContract(Id accountId) {
    Contract testContract = new Contract(
      Name = 'testContract',
      AccountId = accountId,
      StartDate = Date.today(),
      ContractTerm = 12,
      Status = 'Draft',
      SBQQ__RenewalForecast__c = false
    );
    insert testContract;
  }

  static private void insertSubscriptions() {
    List<Product2> products = [
      SELECT Id, Name
      FROM Product2
      WHERE ProductCode LIKE 'PROD %'
    ];
    Contract testContract = [
      SELECT Id, AccountId
      FROM Contract
      WHERE Name = 'testContract'
    ];

    List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();
    for (Product2 product : products) {
      subscriptions.add(
        new SBQQ__Subscription__c(
          SBQQ__Product__c = product.Id,
          SBQQ__Contract__c = testContract.Id,
          SBQQ__Quantity__c = 1,
          SBQQ__Account__c = testContract.AccountId
        )
      );
    }
    insert subscriptions;
  }

  static private void insertProducts() {
    Map<String, String> activeProducts = new Map<String, String>{
      'Prod 1' => 'PROD 1',
      'Prod 2' => 'PROD 2',
      'Prod 3' => 'PROD 3',
      'Prod 4' => 'PROD 4'
    };

    List<Product2> productList = new List<Product2>();

    for (String productName : activeProducts.keySet()) {
      Product2 product = new Product2(
        Name = productName,
        ProductCode = activeProducts.get(productName)
      );
      productList.add(product);
    }
    insert productList;
  }
}