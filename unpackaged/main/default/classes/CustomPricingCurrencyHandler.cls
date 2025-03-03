@SuppressWarnings('Performance-EagerlyLoadedDescribeSObjectResult')
// Not able to set a field describe as deffered.
public with sharing class CustomPricingCurrencyHandler extends DomainLogicHandler {
    List<Custom_Pricing__c> workSet = new List<Custom_Pricing__c>();
    Map<Id, Custom_Pricing__c> oldWorkSet = new Map<Id, Custom_Pricing__c>();
    Set<Id> productIds = new Set<Id>();
    Set<Id> pricebookIds = new Set<Id>();
    List<Schema.SObjectField> syncFields = new List<Schema.SObjectField>{
        Custom_Pricing__c.Minimum_Quantity__c,
        Custom_Pricing__c.Maximum_Quantity__c,
        Custom_Pricing__c.Included_Quantity__c,
        Custom_Pricing__c.Increment_Amount__c
    };

    public override void check(SObject newObj) {
        Custom_Pricing__c customPricing = (Custom_Pricing__c) newObj;
        if (
            customPricing.CurrencyIsoCode == 'USD' &&
            customPricing.Sync_Currencies__c
        ) {
            workSet.add(customPricing);
        }
    }

    public override void check(SObject newObj, SObject oldObj) {
        Custom_Pricing__c customPricing = (Custom_Pricing__c) newObj;
        if (
            customPricing.CurrencyIsoCode == 'USD' &&
            customPricing.Sync_Currencies__c
        ) {
            workSet.add(customPricing);
            oldWorkSet.put(customPricing.Id, (Custom_Pricing__c) oldObj);
        }
    }

    public override void processRecords() {
        if (workSet.isEmpty()) {
            return;
        }

        List<Custom_Pricing__c> updateCustomPricing = new List<Custom_Pricing__c>();
        List<Custom_Pricing__c> insertCustomPricing = new List<Custom_Pricing__c>();
        Set<String> supportedCurrencies = CurrencyUtility.getInstance()
            .getSupportedCurrencies();

        populateProductAndPricebookIds();

        Map<String, List<Custom_Pricing__c>> existingCustomPriceRecords = getMatchingCustomPriceRecordsMap();

        for (Custom_Pricing__c customPricing : workSet) {
            Set<String> existingCurrencies = new Set<String>();
            Set<String> nonExistingCurrencies = new Set<String>();
            List<Custom_Pricing__c> matchingPricingRecords = new List<Custom_Pricing__c>();
            //Use old value if it exists to keep in sync
            Custom_Pricing__c keyRecord = oldWorkSet.containsKey(
                    customPricing.Id
                )
                ? oldWorkSet.get(customPricing.Id)
                : customPricing;
            String key =
                String.valueOf(keyRecord.Product__c) +
                String.valueOf(keyRecord.Price_Book__c) +
                String.valueOf(keyRecord.Minimum_Quantity__c) +
                String.valueOf(keyRecord.Maximum_Quantity__c) +
                keyRecord.Type__c;

            if (existingCustomPriceRecords.containsKey(key)) {
                matchingPricingRecords = existingCustomPriceRecords.get(key);
            }

            for (Custom_Pricing__c matchingPricing : matchingPricingRecords) {
                existingCurrencies.add(matchingPricing.CurrencyIsoCode);
                syncMatchingFields(matchingPricing, customPricing);
                updateCustomPricing.add(matchingPricing);
            }

            for (String currencyIsoCode : supportedCurrencies) {
                if (!existingCurrencies.contains(currencyIsoCode)) {
                    nonExistingCurrencies.add(currencyIsoCode);
                }
            }

            insertCustomPricing.addAll(
                generateNewCustomPricing(customPricing, nonExistingCurrencies)
            );
        }

        update updateCustomPricing;
        insert insertCustomPricing;
    }

    private void populateProductAndPricebookIds() {
        for (Custom_Pricing__c customPricing : workSet) {
            productIds.add(customPricing.Product__c);
            pricebookIds.add(customPricing.Price_Book__c);
        }
    }

    private Map<String, List<Custom_Pricing__c>> getMatchingCustomPriceRecordsMap() {
        Map<String, List<Custom_Pricing__c>> results = new Map<String, List<Custom_Pricing__c>>();

        List<Custom_Pricing__c> existingPricingRecords = [
            SELECT
                Id,
                Product__c,
                Price_Book__c,
                CurrencyIsoCode,
                Minimum_Quantity__c,
                Maximum_Quantity__c,
                Type__c
            FROM Custom_Pricing__c
            WHERE
                Product__c IN :productIds
                AND Price_Book__c IN :pricebookIds
                AND CurrencyIsoCode != 'USD'
        ];

        for (Custom_Pricing__c existingPriceRecord : existingPricingRecords) {
            String key =
                String.valueOf(existingPriceRecord.Product__c) +
                String.valueOf(existingPriceRecord.Price_Book__c) +
                String.valueOf(existingPriceRecord.Minimum_Quantity__c) +
                String.valueOf(existingPriceRecord.Maximum_Quantity__c) +
                existingPriceRecord.Type__c;

            if (!results.containsKey(key)) {
                results.put(key, new List<Custom_Pricing__c>());
            }
            results.get(key).add(existingPriceRecord);
        }
        return results;
    }

    private void syncMatchingFields(
        Custom_Pricing__c matchingPricing,
        Custom_Pricing__c workingRecord
    ) {
        //currency fields
        for (String currencyField : getCustomPricingCurrencyFields()) {
            Decimal convertedPrice = getConvertedPrice(
                workingRecord,
                currencyField,
                matchingPricing.CurrencyIsoCode
            );
            matchingPricing.put(currencyField, convertedPrice);
        }

        //other synced fields
        for (Schema.SObjectField field : syncFields) {
            String fieldName = field.getDescribe().getName();
            if (workingRecord.get(fieldName) != null) {
                matchingPricing.put(fieldName, workingRecord.get(fieldName));
            }
        }
    }

    private Set<String> getCustomPricingCurrencyFields() {
        Set<String> results = new Set<String>();

        Schema.DescribeSObjectResult customPricingDescribe = Custom_Pricing__c.sObjectType.getDescribe(
            SObjectDescribeOptions.DEFERRED
        );
        Map<String, Schema.SObjectField> fields = customPricingDescribe.fields.getMap();
        for (Schema.SObjectField field : fields.values()) {
            Schema.DescribeFieldResult fieldResult = field.getDescribe();
            if (fieldResult.getType() == Schema.DisplayType.CURRENCY) {
                results.add(fieldResult.getName());
            }
        }

        return results;
    }

    private Decimal getConvertedPrice(
        Custom_Pricing__c customPricing,
        String currencyField,
        String currencyIsoCode
    ) {
        Decimal price = (Decimal) customPricing.get(currencyField) != null
            ? (Decimal) customPricing.get(currencyField)
            : 0.0;

        Decimal convertedPrice = 0.0;
        if (customPricing.Round_Sync_Price__c) {
            convertedPrice = CurrencyUtility.getInstance()
                .convertAndRoundPrice(price, currencyIsoCode);
        } else {
            convertedPrice = CurrencyUtility.getInstance()
                .convertPrice(price, currencyIsoCode);
        }

        return convertedPrice;
    }

    private List<Custom_Pricing__c> generateNewCustomPricing(
        Custom_Pricing__c customPricing,
        Set<String> nonExistingCurrencies
    ) {
        List<Custom_Pricing__c> results = new List<Custom_Pricing__c>();

        for (String currencyIsoCode : nonExistingCurrencies) {
            Custom_Pricing__c newPricing = customPricing.clone(
                false,
                true,
                false,
                false
            );
            newPricing.CurrencyIsoCode = currencyIsoCode;
            newPricing.Sync_Currencies__c = false;
            newPricing.Round_Sync_Price__c = false;
            for (String currencyField : getCustomPricingCurrencyFields()) {
                Decimal convertedPrice = getConvertedPrice(
                    customPricing,
                    currencyField,
                    currencyIsoCode
                );
                newPricing.put(currencyField, convertedPrice);
            }
            results.add(newPricing);
        }

        return results;
    }
}