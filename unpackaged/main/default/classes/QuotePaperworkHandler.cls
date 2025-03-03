public with sharing class QuotePaperworkHandler extends DomainLogicHandler {
    private Set<String> supportPackageSKUs = new Set<String>{
        'SP-SILVER',
        'SP-GOLD',
        'SP-PLAT',
        'SP-PLATPLUS',
        '9-10',
        '9-13',
        '9-11'
    };

    private Map<String, String> japaneseSupportPackageMap = new Map<String, String> {
        'Silver Support' => 'Silver サポート',
        'Gold Support' => 'Gold サポート',
        'Platinum Support' => 'Platinum サポート',
        'Platinum Plus Support' => 'Platinum+ サポート'
    };

    List<SBQQ__Quote__c> workSet = new List<SBQQ__Quote__c>();

    public override void check(SObject newObj, SObject oldObj) {
        SBQQ__Quote__c quote = (SBQQ__Quote__c) newObj;

        quote.Has_Legal_Notes__c = quote.Legal_Notes__c != null;
        quote.SBQQ__WatermarkShown__c = quote.SBQQ__Status__c != 'Approved';
        workSet.add((SBQQ__Quote__c) newObj);
    }

    public override void processRecords() {
        Set<Id> quoteIds = new Set<Id>();

        for (SBQQ__Quote__c quote : workSet) {
            quoteIds.add(quote.Id);
        }

        Map<Id, SBQQ__Quote__c> currentQuotes = new Map<Id, SBQQ__Quote__c>(
            [
                SELECT
                    Id,
                    Initial_Term_Amount_Renew__c,
                    SBQQ__SubscriptionTerm__c,
                    Initial_Term_Length__c,
                    (
                        SELECT
                            Id,
                            Paperwork_Product_Type__c,
                            SBQQ__Product__r.No_Proration__c,
                            SBQQ__NetTotal__c,
                            SBQQ__SegmentLabel__c,
                            Initial_Term_Amount__c,
                            SBQQ__ProductCode__c, 
                            SBQQ__Product__c,
                            SBQQ__Product__r.Support_Level__c
                        FROM SBQQ__LineItems__r
                    )
                FROM SBQQ__Quote__c
                WHERE Id IN :quoteIds
            ]
        );

        for(SBQQ__Quote__c quote : workSet) {
            SBQQ__Quote__c currentQuote = currentQuotes.get(quote.Id);
            String supportPackage = 'Silver Support';
            String supportPackageJapan = japaneseSupportPackageMap.get(supportPackage);

            if(currentQuote.SBQQ__LineItems__r == null || currentQuote.SBQQ__LineItems__r.isEmpty()) {
                continue;
            }

            Decimal initialTermTotal = 0.0;
            
            for(SBQQ__QuoteLine__c quoteLine : currentQuote.SBQQ__LineItems__r) {
                if(quoteLine == null) {
                    continue;
                }

                if(quoteLine?.Initial_Term_Amount__c != null) {
                    initialTermTotal += quoteLine?.Initial_Term_Amount__c;
                }                

                if(supportPackageSKUs.contains(quoteLine?.SBQQ__ProductCode__c)) {
                    supportPackage = quoteLine?.SBQQ__Product__r.Support_Level__c;
                    supportPackageJapan = japaneseSupportPackageMap.get(supportPackage);
                }
            }

            quote.Initial_Term_Amount_Renew__c = initialTermTotal;
            quote.Support_Package__c = supportPackage;
            quote.Support_Package_Japan__c = supportPackageJapan;
        }
    }
}