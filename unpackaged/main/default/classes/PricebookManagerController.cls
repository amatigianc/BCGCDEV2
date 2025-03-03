public with sharing class PricebookManagerController {
    @AuraEnabled
    public static List<PricebookEntry> getUSDPricebookEntry(Id recordId) {
        try {
            if(recordId == null) {
                throw new AuraHandledException('Null recordId');
            }
            
            return [
                SELECT
                    Id,
                    IsActive,
                    CurrencyIsoCode,
                    UnitPrice,
                    Pricebook2Id,
                    Product2Id,
                    UseStandardPrice,
                    Pricebook_Name__c
                FROM PricebookEntry
                WHERE Product2Id = :recordId AND CurrencyIsoCode = 'USD'
                ORDER BY CreatedDate ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void toggleActivation(PricebookEntry pbe) {
        try {
            List<PricebookEntry> pricebookEntries = [
                SELECT Id, IsActive
                FROM PricebookEntry
                WHERE
                    Product2Id = :pbe.Product2Id
                    AND Pricebook2Id = :pbe.Pricebook2Id
            ];

            for (PricebookEntry entry : pricebookEntries) {
                entry.IsActive = !entry.IsActive;
            }

            update pricebookEntries;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePricebookEntry(PricebookEntry pbe) {
        try {
            List<PricebookEntry> pricebookEntries = [
                SELECT Id
                FROM PricebookEntry
                WHERE
                    Product2Id = :pbe.Product2Id
                    AND Pricebook2Id = :pbe.Pricebook2Id
            ];

            delete pricebookEntries;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createUpdatePricebookEntries(
        String product2Id,
        String pricebook2Id,
        Decimal unitPrice
    ) {
        try {
            PricebookEntry usdPricebookEntry = new PricebookEntry(
                Product2Id = product2Id,
                Pricebook2Id = pricebook2Id,
                UnitPrice = unitPrice
            );
            List<PricebookEntry> existingPricebookEntries = [
                SELECT
                    Id,
                    IsActive,
                    CurrencyIsoCode,
                    UnitPrice,
                    Pricebook2Id,
                    Product2Id
                FROM PricebookEntry
                WHERE
                    Pricebook2Id = :usdPricebookEntry.Pricebook2Id
                    AND Product2Id = :usdPricebookEntry.Product2Id
                    AND CurrencyIsoCode != 'USD'
            ];

            Set<String> supportedCurrencies = CurrencyUtility.getInstance().getSupportedCurrencies();
            Set<String> existingCurrencies = new Set<String>();
            Set<String> newCurrencies = new Set<String>();

            for (PricebookEntry pbe : existingPricebookEntries) {
                if (supportedCurrencies.contains(pbe.CurrencyIsoCode)) {
                    existingCurrencies.add(pbe.CurrencyIsoCode);
                }
                Decimal price = CurrencyUtility.getInstance()
                    .convertAndRoundPrice(
                        usdPricebookEntry.UnitPrice,
                        pbe.CurrencyIsoCode
                    );
                pbe.UnitPrice = price;
            }

            for (String currencyCode : supportedCurrencies) {
                if (!existingCurrencies.contains(currencyCode)) {
                    newCurrencies.add(currencyCode);
                }
            }

            List<PricebookEntry> newPricebookEntries = generateNewPricebookEntries(
                newCurrencies,
                usdPricebookEntry
            );

            insert newPricebookEntries;
            update existingPricebookEntries;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<PricebookEntry> generateNewPricebookEntries(
        Set<String> newCurrencies,
        PricebookEntry usdPricebookEntry
    ) {
        List<PricebookEntry> results = new List<PricebookEntry>();
        for (String currenyCode : newCurrencies) {
            Decimal price = CurrencyUtility.getInstance()
                .convertAndRoundPrice(usdPricebookEntry.UnitPrice, currenyCode);
            results.add(
                new PricebookEntry(
                    IsActive = true,
                    Pricebook2Id = usdPricebookEntry.Pricebook2Id,
                    Product2Id = usdPricebookEntry.Product2Id,
                    UnitPrice = price,
                    CurrencyIsoCode = currenyCode
                )
            );
        }
        return results;
    }
}