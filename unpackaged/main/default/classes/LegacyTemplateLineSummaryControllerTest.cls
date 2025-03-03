@IsTest
public class LegacyTemplateLineSummaryControllerTest {
  /**
   * I apologize for bringing this monstrosity over from legacy salesforce. But we had no choice.
   */
  @TestSetup
  static void makeData() {
    Account a = AccountTestFactory.createCustomer();

    Opportunity o = OpportunityTestFactory.getStage1Opp(a.Id);
    insert o;
  }

  @IsTest(seeAllData=false)
  public static void legacyTemplateLineSummaryControlTest() {
    Account a = [
      SELECT Id, Name
      FROM Account
      WHERE Name LIKE 'AccountTestFactory%'
    ];
    Opportunity o = [
      SELECT Id, AccountId, Name, Deal_Type__c, StageName, CloseDate
      FROM Opportunity
      WHERE AccountId = :a.Id
    ];

    Product2 p1 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'Bundle',
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    Product2 p2 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'MDQNonBundle',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12
    );
    Product2 p3 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'MDQBundled',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12
    );
    Product2 p31 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'MDQBundled',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12
    );
    Product2 p4 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'ProductNotBundle',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12
    );
    Product2 p5 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'ComponentNonMDQ',
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    Product2 p6 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'ComponentNonMDQ',
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    Product2 p7 = new Product2(
      Name = 'Support Package',
      IsActive = true,
      ProductCode = 'ComponentNonMDQ',
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert new List<Product2>{ p1, p2, p3, p4, P5, p6, p31, p7 };

    Id pricebookId = Test.getStandardPricebookId();
    PricebookEntry standardPrice1 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p1.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    PricebookEntry standardPrice2 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p2.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    PricebookEntry standardPrice3 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p3.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    PricebookEntry standardPrice31 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p31.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    PricebookEntry standardPrice4 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p4.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    PricebookEntry standardPrice5 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p5.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    PricebookEntry standardPrice6 = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = p6.Id,
      UnitPrice = 10000,
      IsActive = true
    );
    insert new List<PricebookEntry>{
      standardPrice1,
      standardPrice2,
      standardPrice3,
      standardPrice4,
      standardPrice5,
      standardPrice6,
      standardPrice31
    };

    SBQQ__Dimension__c pd3 = new SBQQ__Dimension__c(
      SBQQ__Product__c = p3.id,
      Name = 'MDQ',
      SBQQ__Type__c = 'Year'
    );
    SBQQ__Dimension__c pd31 = new SBQQ__Dimension__c(
      SBQQ__Product__c = p31.id,
      Name = 'MDQ',
      SBQQ__Type__c = 'Year'
    );
    SBQQ__Dimension__c pd5 = new SBQQ__Dimension__c(
      SBQQ__Product__c = p5.id,
      Name = 'MDQ',
      SBQQ__Type__c = 'Year'
    );
    SBQQ__Dimension__c pd6 = new SBQQ__Dimension__c(
      SBQQ__Product__c = p6.id,
      Name = 'MDQ',
      SBQQ__Type__c = 'Year'
    );
    SBQQ__Dimension__c pd7 = new SBQQ__Dimension__c(
      SBQQ__Product__c = p7.id,
      Name = 'MDQ',
      SBQQ__Type__c = 'Year'
    );
    insert new List<SBQQ__Dimension__c>{ pd3, pd5, pd6, pd31, pd7 };

    SBQQ__Quote__c quote1 = QuoteTestFactory.getBaseQuote();

    quote1.SBQQ__Opportunity2__c = o.id;
    quote1.SBQQ__SubscriptionTerm__c = 14;

    insert quote1;

    SBQQ__QuoteLine__c line1 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p1.Id,
      SBQQ__ListPrice__c = 0,
      SBQQ__Quantity__c = 1,
      SBQQ__Bundle__c = true,
      Custom_Product_Name__c = 'Test Product',
      Custom_Product_Description__c = 'lol',
      Description_Updated__c = 'lol',
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    insert line1;
    SBQQ__QuoteLine__c line2 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p2.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Quantity__c = 1,
      SBQQ__SegmentIndex__c = 2,
      SBQQ__Bundle__c = false,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line3 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p3.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Quantity__c = 1,
      SBQQ__SegmentKey__c = '1234567891234',
      SBQQ__SegmentIndex__c = 1,
      SBQQ__RequiredBy__c = line1.Id,
      SBQQ__Bundle__c = false,
      SBQQ__OptionLevel__c = 1,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line31 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p3.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Discount__c = 0.5,
      SBQQ__Quantity__c = 1,
      SBQQ__SegmentKey__c = '1234567891234',
      SBQQ__SegmentIndex__c = 2,
      SBQQ__RequiredBy__c = line1.Id,
      SBQQ__Bundle__c = false,
      SBQQ__OptionLevel__c = 1,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line4 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p4.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Quantity__c = 1,
      SBQQ__Bundle__c = false,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line5 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p5.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Quantity__c = 1,
      SBQQ__RequiredBy__c = line1.Id,
      Custom_Product_Name__c = 'Test Product',
      Custom_Product_Description__c = 'lol',
      SBQQ__Bundle__c = false,
      SBQQ__OptionLevel__c = 1,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line6 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p6.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Quantity__c = 1,
      Description_Updated__c = 'lol',
      SBQQ__RequiredBy__c = line1.Id,
      SBQQ__Bundle__c = false,
      SBQQ__OptionLevel__c = 1,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SegmentIndex__c = 1
    );
    SBQQ__QuoteLine__c line7 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p7.Id,
      SBQQ__ListPrice__c = 0,
      SBQQ__Quantity__c = 1,
      SBQQ__RequiredBy__c = line1.Id,
      SBQQ__Bundle__c = true,
      SBQQ__SegmentKey__c = '1234567891234',
      SBQQ__SegmentIndex__c = 1,
      SBQQ__OptionLevel__c = 1,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line9 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p7.Id,
      SBQQ__ListPrice__c = 0,
      SBQQ__Quantity__c = 1,
      SBQQ__RequiredBy__c = line1.Id,
      SBQQ__Bundle__c = true,
      SBQQ__SegmentKey__c = '1234567891234',
      SBQQ__SegmentIndex__c = 2,
      SBQQ__OptionLevel__c = 1,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    SBQQ__QuoteLine__c line8 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p7.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Discount__c = 0.5,
      SBQQ__Quantity__c = 1,
      SBQQ__Bundle__c = false,
      SBQQ__ProductSubscriptionType__c = 'One-Time',
      SBQQ__SubscriptionType__c = 'One-Time',
      SBQQ__SubscriptionPricing__c = ''
    );
    insert new List<SBQQ__QuoteLine__c>{
      line2,
      line3,
      line4,
      line5,
      line6,
      line31,
      line7,
      line8,
      line9
    };

    SBQQ__QuoteLine__c line52 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote1.Id,
      SBQQ__Product__c = p5.Id,
      SBQQ__ListPrice__c = 100,
      SBQQ__Discount__c = 0.5,
      SBQQ__Quantity__c = 1,
      SBQQ__RequiredBy__c = line5.Id,
      Custom_Product_Name__c = 'Test Product',
      Custom_Product_Description__c = 'lol',
      SBQQ__Bundle__c = false,
      SBQQ__SegmentIndex__c = 1,
      SBQQ__SegmentKey__c = '1234567890123',
      SBQQ__OptionLevel__c = 2,
      SBQQ__ProductSubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionType__c = 'Renewable',
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    insert line52;

    PageReference pageRef = Page.LegacyTemplateLineSummary;
    Test.setCurrentPageReference(pageRef);
    pageRef.getParameters().put('qId', quote1.Id);

    LegacyTemplateLineSummaryController controller = new LegacyTemplateLineSummaryController();

    PageReference pageRef2 = Page.ContractHeader;
    Test.setCurrentPageReference(pageRef2);
    pageRef2.getParameters().put('qId', quote1.Id);

    ContractHeaderController controller2 = new ContractHeaderController();
  }
}