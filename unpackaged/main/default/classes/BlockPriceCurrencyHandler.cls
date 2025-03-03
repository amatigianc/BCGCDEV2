public with sharing class BlockPriceCurrencyHandler extends DomainLogicHandler {
    List<SBQQ__BlockPrice__c> workSet = new List<SBQQ__BlockPrice__c>();
    Set<Id> productIds = new Set<Id>();
    Set<Id> pricebookIds = new Set<Id>();

    public override void check(SObject newObj) {
        SBQQ__BlockPrice__c blockPrice = (SBQQ__BlockPrice__c) newObj;
        if (
            blockPrice.Sync_Currencies__c && blockPrice.CurrencyIsoCode == 'USD'
        ) {
            workSet.add(blockPrice);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        SBQQ__BlockPrice__c blockPrice = (SBQQ__BlockPrice__c) newObj;
        if (
            blockPrice.Sync_Currencies__c && blockPrice.CurrencyIsoCode == 'USD'
        ) {
            workSet.add(blockPrice);
        }
    }

    public override void processRecords() {
        if (workSet.isEmpty()) {
            return;
        }

        List<SBQQ__BlockPrice__c> updateBlockPrices = new List<SBQQ__BlockPrice__c>();
        List<SBQQ__BlockPrice__c> insertBlockPrices = new List<SBQQ__BlockPrice__c>();
        Set<String> supportedCurrencies = CurrencyUtility.getInstance()
            .getSupportedCurrencies();

        populateProductAndPricebookIds();

        Map<String, List<SBQQ__BlockPrice__c>> existingBlockPriceRecords = getMatchingBlockPriceRecordsMap();

        for (SBQQ__BlockPrice__c blockPrice : workSet) {
            Set<String> existingCurrencies = new Set<String>();
            Set<String> nonExistingCurrencies = new Set<String>();
            List<SBQQ__BlockPrice__c> matchingBlockPriceRecords = new List<SBQQ__BlockPrice__c>();
            String key =
                String.valueOf(blockPrice.SBQQ__Product__c) +
                String.valueOf(blockPrice.SBQQ__PriceBook2__c) +
                String.valueOf(blockPrice.SBQQ__LowerBound__c) +
                String.valueOf(blockPrice.SBQQ__UpperBound__c) +
                blockPrice.Name;

            if (existingBlockPriceRecords.containsKey(key)) {
                matchingBlockPriceRecords = existingBlockPriceRecords.get(key);
            }

            for (
                SBQQ__BlockPrice__c matchingBlockPrice : matchingBlockPriceRecords
            ) {
                existingCurrencies.add(matchingBlockPrice.CurrencyIsoCode);
                matchingBlockPrice.SBQQ__Price__c = CurrencyUtility.getInstance()
                    .convertPrice(
                        blockPrice.SBQQ__Price__c,
                        matchingBlockPrice.CurrencyIsoCode
                    );
                updateBlockPrices.add(matchingBlockPrice);
            }

            for (String currencyIsoCode : supportedCurrencies) {
                if (!existingCurrencies.contains(currencyIsoCode)) {
                    nonExistingCurrencies.add(currencyIsoCode);
                }
            }

            insertBlockPrices.addAll(
                generateNewBlockPrice(blockPrice, nonExistingCurrencies)
            );
        }

        update updateBlockPrices;
        insert insertBlockPrices;
    }

    private void populateProductAndPricebookIds() {
        for (SBQQ__BlockPrice__c blockPrice : workSet) {
            productIds.add(blockPrice.SBQQ__Product__c);
            pricebookIds.add(blockPrice.SBQQ__PriceBook2__c);
        }
    }

    private Map<String, List<SBQQ__BlockPrice__c>> getMatchingBlockPriceRecordsMap() {
        Map<String, List<SBQQ__BlockPrice__c>> results = new Map<String, List<SBQQ__BlockPrice__c>>();

        List<SBQQ__BlockPrice__c> existingBlockPriceRecords = [
            SELECT
                Id,
                SBQQ__Product__c,
                SBQQ__PriceBook2__c,
                CurrencyIsoCode,
                SBQQ__UpperBound__c,
                SBQQ__LowerBound__c,
                Name
            FROM SBQQ__BlockPrice__c
            WHERE
                SBQQ__Product__c IN :productIds
                AND SBQQ__PriceBook2__c IN :pricebookIds
                AND CurrencyIsoCode != 'USD'
        ];

        for (
            SBQQ__BlockPrice__c existingBlockPrice : existingBlockPriceRecords
        ) {
            String key =
                String.valueOf(existingBlockPrice.SBQQ__Product__c) +
                String.valueOf(existingBlockPrice.SBQQ__PriceBook2__c) +
                String.valueOf(existingBlockPrice.SBQQ__LowerBound__c) +
                String.valueOf(existingBlockPrice.SBQQ__UpperBound__c) +
                existingBlockPrice.Name;

            if (!results.containsKey(key)) {
                results.put(key, new List<SBQQ__BlockPrice__c>());
            }
            results.get(key).add(existingBlockPrice);
        }
        return results;
    }

    private List<SBQQ__BlockPrice__c> generateNewBlockPrice(
        SBQQ__BlockPrice__c blockPrice,
        Set<String> nonExistingCurrencies
    ) {
        List<SBQQ__BlockPrice__c> results = new List<SBQQ__BlockPrice__c>();

        for (String currencyIsoCode : nonExistingCurrencies) {
            SBQQ__BlockPrice__c newPricing = blockPrice.clone(
                false,
                true,
                false,
                false
            );
            newPricing.CurrencyIsoCode = currencyIsoCode;
            newPricing.Sync_Currencies__c = false;
            newPricing.SBQQ__Price__c = CurrencyUtility.getInstance()
                .convertPrice(blockPrice.SBQQ__Price__c, currencyIsoCode);
            results.add(newPricing);
        }
        return results;
    }
}