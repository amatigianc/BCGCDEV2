public with sharing class ContractHeaderController {
  private Set<String> supportPackageSKUs = new Set<String>{
    'SP-SILVER',
    'SP-GOLD',
    'SP-PLAT',
    'SP-PLATPLUS',
    '9-10',
    '9-13',
    '9-11'
  };

  private List<String> familyOrder = new List<String>{
    'Video Cloud Platform',
    'Media Studio',
    'Marketing Studio',
    'VMS Platform',
    'EVS Platform',
    'OTT Flow',
    'Zencoder',
    'Once',
    'Brightcove Engage',
    'Brightcove Beacon',
    'Beacon',
    'Brightcove Continuum',
    'Brightcove Audience Insights',
    'Audience Insights',
    'Brightcove Campaign'
  };

  private Map<String, String> familyToTitleMap = new Map<String, String>{
    'Video Cloud Platform' => 'Video Cloud Order Form',
    'Marketing Studio' => 'Marketing Studio Order Form',
    'Media Studio' => 'Brightcove Media Studio Order Form',
    'VMS Platform' => 'Video Marketing Suite Order Form',
    'EVS Platform' => 'Enterprise Video Suite Order Form',
    'OTT Flow' => 'OTT Flow Order Form',
    'Zencoder' => 'Zencoder&reg; Order Form',
    'Once' => 'Brightcove Once Order Form',
    'Brightcove Engage' => 'Brightcove Engage&#8482;',
    'Brightcove Beacon' => 'Brightcove Beacon&reg; Order Form',
    'Beacon' => 'Brightcove Beacon&reg;',
    'Brightcove Continuum' => 'Brightcove Continuum&#8482;',
    'Brightcove Audience Insights' => 'Brightcove Audience Insights&#8482; Order Form',
    'Audience Insights' => 'Brightcove Audience Insights&#8482; Order Form',
    'Brightcove Campaign' => 'Brightcove Campaign&#8482;'
  };

  private Set<String> productFamilies;

  public SBQQ__Quote__c quote { get; set; }
  public List<SBQQ__QuoteLine__c> quoteLines { get; set; }

  public String documentTitle { get; set; }
  public String documentTitleSymbol { get; set; }
  public String documentTitleEnd { get; set; }
  public Date dateOfExistingAgreement { get; set; }
  public String supportPackage { get; set; }
  public String autoRenewal { get; set; }

  public Boolean hasBAISetup { get; set; }

  public ContractHeaderController() {
    Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
    productFamilies = new Set<String>();

    quote = getQuote(quoteId);
    quoteLines = getQuoteLines(quoteId);

    processQuoteLines();

    setTitle();
    dateOfExistingAgreement = quote.Renewed_Contract__r.StartDate;
    autoRenewal = quote.Auto_Renew__c ? 'Yes' : 'No';
  }

  private void setTitle() {
    if (quote.isAddOn__c) {
      documentTitle = 'Additional Services Order';
      return;
    }

    documentTitle = 'Brightcove Order Form';

    for (String family : familyOrder) {
      if (productFamilies.contains(family)) {
        documentTitle = familyToTitleMap.get(family);
        return;
      }
    }
  }

  private void processQuoteLines() {
    //extract the info we need out of the quote lines
    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if (quoteLine.SBQQ__ProductFamily__c != '') {
        productFamilies.add(quoteLine.SBQQ__ProductFamily__c);
      }

      if (quoteLine.SBQQ__ProductCode__c == 'SV-BAI-SETUP') {
        hasBAISetup = true;
      }

      if (
        quoteLine.Product_Type__c == 'Support' &&
        supportPackageSKUs.contains(quoteLine.SBQQ__ProductCode__c)
      ) {
        supportPackage = quoteLine.SBQQ__ProductName__c;
      }
    }
  }

  private SBQQ__Quote__c getQuote(Id quoteId) {
    return [
      SELECT
        Id,
        Name,
        SBQQ__Type__c,
        SBQQ__BillingName__c,
        SBQQ__BillingStreet__c,
        SBQQ__BillingCity__c,
        SBQQ__BillingState__c,
        SBQQ__BillingPostalCode__c,
        SBQQ__BillingCountry__c,
        SBQQ__StartDate__c,
        CurrencyIsoCode,
        SBQQ__Opportunity2__r.Invoice_Email_s__c,
        SBQQ__Opportunity2__r.Acting_as_Agency__c,
        SBQQ__Opportunity2__r.Deal_Type__c,
        SBQQ__Opportunity2__r.Requested_CDN__c,
        SBQQ__Opportunity2__r.Amount_Due_to_BC__c,
        SBQQ__Opportunity2__r.Early_Renewal_Credit_Amount__c,
        Due_Date__c,
        End_Customer_Name__c,
        SBQQ__PaymentTerms__c,
        SBQQ__BillingFrequency__c,
        SBQQ__SubscriptionTerm__c,
        SBQQ__RenewalTerm__c,
        SBQQ__NetAmount__c,
        SBQQ__CustomerAmount__c,
        Auto_Renew__c,
        Renewed_Contract__r.StartDate,
        Outgoing_Document_Effective_Date__c,
        Outgoing_Document_Hide_Start_Date__c,
        Outgoing_Document_Show_Renewal_Term__c,
        Outgoing_Document_Mandatory_Renewal__c,
        Outgoing_Document_Show_First_Term_Fees__c,
        Mandatory_Renewal_Term__c,
        Initial_Term_Length__c,
        Renewal_Term_Amount__c,
        Initial_Term_Total_Amount__c,
        ARR__c,
        Single_Term__c,
        isAddOn__c,
        isNotAddOn__c,
        SBQQ__Opportunity2__r.Contract_Id__c
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
      LIMIT 1
    ];
  }

  private List<SBQQ__QuoteLine__c> getQuoteLines(Id quoteId) {
    return [
      SELECT
        Id,
        SBQQ__ProductFamily__c,
        SBQQ__ProductName__c,
        SBQQ__ProductCode__c,
        Product_Type__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :quoteId
    ];
  }
}