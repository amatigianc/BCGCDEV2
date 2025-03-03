@isTest
public with sharing class PersistentIdHandlerTest {
  @TestSetup
  static void setup() {
    TestUserProvisioner provisioner = new TestUserProvisioner(
      UserInfo.getUserId()
    );
    provisioner.setLicenses(
      new List<String>{ 'SalesforceCPQ_CPQStandardPerm' }
    );
    provisioner.setPermissions(
      new List<String>{ 'Global_Read', 'SteelBrickCPQUser' }
    );
    provisioner.assignPermissions();
  }

  @isTest
  private static void testLeadGuidAssignment() {
    Lead record = LeadTestFactory.createLead();

    record = [SELECT Id, GUID__c FROM Lead WHERE Id = :record.Id];
    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testCaseGuidAssignment() {
    Account account = AccountTestFactory.createCustomer();
    Contact contact = ContactTestFactory.createContact(account);
    Case record = new Case(
      AccountId = account.Id,
      ContactId = contact.Id,
      Origin = 'Email'
    );
    insert record;

    record = [SELECT Id, GUID__c FROM Case WHERE Id = :record.Id];
    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testContactGuidAssignment() {
    Account account = AccountTestFactory.createCustomer();
    Contact record = ContactTestFactory.createContact(account);

    record = [SELECT Id, GUID__c FROM Contact WHERE Id = :record.Id];
    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testOppGuidAssignment() {
    Account account = AccountTestFactory.createCustomer();

    Opportunity opp = OpportunityTestFactory.getStage1Opp(account.Id);
    insert opp;

    opp = [SELECT Id, GUID__c FROM Opportunity WHERE Id = :opp.Id];

    System.assertNotEquals(null, opp.GUID__c, 'GUID not assigned to record.');
    System.assertEquals(
      36,
      opp.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testOrderGuidAssignment() {
    Account account = AccountTestFactory.createCustomer();

    Order record = new Order(
      AccountId = account.Id,
      Name = 'PersistentIdHandlerTest',
      EffectiveDate = Date.today(),
      Status = Order.Status.getDescribe().getPicklistValues()[0].getValue()
    );
    insert record;

    record = [SELECT Id, GUID__c FROM Order WHERE Id = :record.Id];

    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testCustomPricingGuidAssignment() {
    Custom_Pricing__c record = new Custom_Pricing__c(
      Maximum_Quantity__c = 10,
      Minimum_Quantity__c = 1,
      Type__c = Custom_Pricing__c.Type__c.getDescribe().getPicklistValues()[0]
        .getValue()
    );
    insert record;

    record = [
      SELECT Id, GUID__c
      FROM Custom_Pricing__c
      WHERE Id = :record.Id
    ];

    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testQuoteGuidAssignment() {
    SBQQ__Quote__c record = QuoteTestFactory.createBaseQuote();

    record = [SELECT Id, GUID__c FROM SBQQ__Quote__c WHERE Id = :record.Id];

    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testSubscriptionGuidAssignment() {
    SBQQ__Subscription__c record = new SBQQ__Subscription__c(
      SBQQ__Quantity__c = 1
    );
    insert record;

    record = [
      SELECT Id, GUID__c
      FROM SBQQ__Subscription__c
      WHERE Id = :record.Id
    ];

    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testContractGuidAssignment() {
    Account account = AccountTestFactory.createCustomer();

    Contract record = new Contract(
      AccountId = account.Id,
      StartDate = system.today(),
      ContractTerm = 12,
      Status = 'Draft'
    );
    insert record;

    record = [SELECT Id, GUID__c FROM Contract WHERE Id = :record.Id];

    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testBlockPricingGuidAssignment() {
    SBQQ__BlockPrice__c record = new SBQQ__BlockPrice__c();
    insert record;

    record = [
      SELECT Id, GUID__c
      FROM SBQQ__BlockPrice__c
      WHERE Id = :record.Id
    ];

    System.assertNotEquals(
      null,
      record.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      record.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testAccountGuidAssignment() {
    Account account = AccountTestFactory.createCustomer();

    account = [SELECT Id, GUID__c FROM Account WHERE Id = :account.Id];

    System.assertNotEquals(
      null,
      account.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      account.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testProductGuidAssignment() {
    Product2 product = new Product2(Name = 'PersistentIdHandlerTest');
    insert product;

    product = [SELECT Id, GUID__c FROM Product2 WHERE Id = :product.Id];

    SBQQ__Dimension__c dimension = new SBQQ__Dimension__c(
      Name = 'Yearly Ramp - USD',
      CurrencyIsoCode = 'USD',
      SBQQ__Product__c = product.Id
    );

    insert dimension;

    dimension = [
      SELECT Id, GUID__c
      FROM SBQQ__Dimension__c
      WHERE Id = :dimension.Id
    ];

    System.assertNotEquals(
      null,
      product.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      product.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      dimension.GUID__c,
      'GUID not assigned to dimension record.'
    );
    System.assertEquals(
      36,
      dimension.GUID__c.length(),
      'Invalid GUID length assigned. dimension'
    );
  }

  @isTest
  private static void testProductOptionGuidAssignment() {
    SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c(
      SBQQ__Number__c = 1
    );
    insert productOption;

    productOption = [
      SELECT Id, GUID__c
      FROM SBQQ__ProductOption__c
      WHERE Id = :productOption.Id
    ];

    System.assertNotEquals(
      null,
      productOption.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      productOption.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testProductFeatureGuidAssignment() {
    SBQQ__ProductFeature__c productFeature = new SBQQ__ProductFeature__c(
      Name = 'PersistentIdHandlerTest',
      SBQQ__Number__c = 1
    );
    insert productFeature;

    productFeature = [
      SELECT Id, GUID__c
      FROM SBQQ__ProductFeature__c
      WHERE Id = :productFeature.Id
    ];

    System.assertNotEquals(
      null,
      productFeature.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      productFeature.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testPricebookGuidAssignment() {
    Pricebook2 pricebook = new Pricebook2(Name = 'PersistentIdHandlerTest');
    insert pricebook;

    pricebook = [
      SELECT Id, GUID__c
      FROM Pricebook2
      WHERE Id = :pricebook.Id
    ];

    System.assertNotEquals(
      null,
      pricebook.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      pricebook.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testAAGuidAssignment() {
    sbaa__Approver__c approver = new sbaa__Approver__c(Name = 'Test User');
    insert approver;

    sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
      Name = 'Test Rule',
      sbaa__TargetObject__c = 'SBQQ__Quote__c'
    );
    insert chain;

    sbaa__EmailTemplate__c template = new sbaa__EmailTemplate__c(
      Name = 'Test Template',
      sbaa__TemplateId__c = 'Irrelevant'
    );
    insert template;

    sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
      Name = 'Test Rule',
      sbaa__TargetObject__c = 'SBQQ__Quote__c'
    );
    insert rule;

    sbaa__ApprovalVariable__c variable = new sbaa__ApprovalVariable__c(
      Name = 'Test Variable',
      sbaa__Type__c = 'Summary',
      sbaa__AggregateField__c = 'Quantity',
      sbaa__AggregateFunction__c = 'Sum'
    );
    insert variable;

    approver = [
      SELECT Id, GUID__c
      FROM sbaa__Approver__c
      WHERE Id = :approver.Id
    ];

    chain = [
      SELECT Id, GUID__c
      FROM sbaa__ApprovalChain__c
      WHERE Id = :chain.Id
    ];

    template = [
      SELECT Id, GUID__c
      FROM sbaa__EmailTemplate__c
      WHERE Id = :template.Id
    ];

    rule = [
      SELECT Id, GUID__c
      FROM sbaa__ApprovalRule__c
      WHERE Id = :rule.Id
    ];

    variable = [
      SELECT Id, GUID__c
      FROM sbaa__ApprovalVariable__c
      WHERE Id = :variable.Id
    ];

    System.assertNotEquals(
      null,
      approver.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      approver.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(null, chain.GUID__c, 'GUID not assigned to record.');
    System.assertEquals(
      36,
      chain.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      template.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      template.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(null, rule.GUID__c, 'GUID not assigned to record.');
    System.assertEquals(
      36,
      rule.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      variable.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      variable.GUID__c.length(),
      'Invalid GUID length assigned.'
    );
  }

  @isTest
  private static void testCPQGuidAssignment() {
    SBQQ.TriggerControl.disable();

    SBQQ__ProductRule__c rule = new SBQQ__ProductRule__c(
      SBQQ__EvaluationEvent__c = 'Always',
      SBQQ__Scope__c = 'Product',
      SBQQ__Type__c = 'Selection',
      SBQQ__ConditionsMet__c = 'All',
      Name = 'Test'
    );

    insert rule;

    SBQQ__ProductAction__c prodAction = new SBQQ__ProductAction__c(
      SBQQ__Rule__c = rule.Id,
      SBQQ__Type__c = 'Add'
    );
    insert prodAction;

    SBQQ__ErrorCondition__c errorCondition = new SBQQ__ErrorCondition__c(
      SBQQ__Rule__c = rule.Id,
      SBQQ__TestedObject__c = 'Quote',
      SBQQ__TestedField__c = 'SBQQ__Type__c',
      SBQQ__Operator__c = 'equals',
      SBQQ__FilterType__c = 'Value',
      SBQQ__FilterValue__c = 'Amendment'
    );
    insert errorCondition;

    SBQQ__ConfigurationRule__c configRule = new SBQQ__ConfigurationRule__c(
      SBQQ__ProductRule__c = rule.Id
    );
    insert configRule;

    SBQQ__QuoteTemplate__c quoteTemplate = new SBQQ__QuoteTemplate__c(
      Name = 'Test',
      SBQQ__DeploymentStatus__c = 'In Development',
      SBQQ__PageHeight__c = 11.0,
      SBQQ__PageWidth__c = 8.0,
      SBQQ__TopMargin__c = 1.0,
      SBQQ__BottomMargin__c = 1.0,
      SBQQ__LeftMargin__c = 0.5,
      SBQQ__RightMargin__c = 0.5,
      SBQQ__FontFamily__c = 'Helvetica',
      SBQQ__FontSize__c = 9.0,
      SBQQ__BorderColor__c = '000000',
      SBQQ__ShadingColor__c = 'FFFFFF',
      SBQQ__TermBodyIndent__c = 15
    );
    insert quoteTemplate;

    rule = [
      SELECT Id, GUID__c
      FROM SBQQ__ProductRule__c
      WHERE Id = :rule.Id
    ];

    prodAction = [
      SELECT Id, GUID__c
      FROM SBQQ__ProductAction__c
      WHERE Id = :prodAction.Id
    ];

    errorCondition = [
      SELECT Id, GUID__c
      FROM SBQQ__ErrorCondition__c
      WHERE Id = :errorCondition.Id
    ];

    configRule = [
      SELECT Id, GUID__c
      FROM SBQQ__ConfigurationRule__c
      WHERE Id = :configRule.Id
    ];

    quoteTemplate = [
      SELECT Id, GUID__c
      FROM SBQQ__QuoteTemplate__c
      WHERE Id = :quoteTemplate.Id
    ];

    System.assertNotEquals(null, rule.GUID__c, 'GUID not assigned to record.');
    System.assertEquals(
      36,
      rule.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      prodAction.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      prodAction.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      errorCondition.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      errorCondition.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      configRule.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      configRule.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    System.assertNotEquals(
      null,
      quoteTemplate.GUID__c,
      'GUID not assigned to record.'
    );
    System.assertEquals(
      36,
      quoteTemplate.GUID__c.length(),
      'Invalid GUID length assigned.'
    );

    SBQQ.TriggerControl.enable();
  }
}