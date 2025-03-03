@IsTest
public with sharing class CustomPricingCurrencyHandlerTest {
    @TestSetup
    static void setupData() {
        Product2 testProd = new Product2(
            Name = 'Test Product Custom Pricing',
            ProductCode = 'TST-PRD-CSTM-PRICE'
        );

        insert testProd;

        Id standardPricebookId = Test.getStandardPricebookId();

        insert new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = testProd.Id,
                UnitPrice = 1500,
                CurrencyIsoCode = 'USD',
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = testProd.Id,
                UnitPrice = 1500,
                CurrencyIsoCode = 'GBP',
                IsActive = true
            )
        };
    }

    @IsTest
    public static void testInsertCustomPricingWithRoundAndSync() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Custom Pricing'
        ]
        .Id;

        Id standardPricebookId = Test.getStandardPricebookId();

        Test.startTest();

        insert new Custom_Pricing__c(
            Type__c = 'QCP - Increment Pricing',
            Product__c = productId,
            Price_Book__c = standardPricebookId,
            Base_Price__c = 15000,
            Minimum_Quantity__c = 1,
            Maximum_Quantity__c = 100000,
            CurrencyIsoCode = 'USD',
            Sync_Currencies__c = true,
            Round_Sync_Price__c = true
        );

        Test.stopTest();

        List<Custom_Pricing__c> customPricingResults = [
            SELECT Id, Base_Price__c
            FROM Custom_Pricing__c
            WHERE
                Product__c = :productId
                AND Price_Book__c = :standardPricebookId
                AND CurrencyIsoCode != 'USD'
        ];

        System.assert(
            customPricingResults.size() > 0,
            'Custom Pricing records were not created for other currencies when expected'
        );
    }

    @IsTest
    public static void testUpdateCustomPricingWithSyncOnly() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Custom Pricing'
        ]
        .Id;

        Id standardPricebookId = Test.getStandardPricebookId();

        Custom_Pricing__c mainCustomPricing = new Custom_Pricing__c(
            Type__c = 'QCP - Increment Pricing',
            Product__c = productId,
            Price_Book__c = standardPricebookId,
            Base_Price__c = 15000,
            Minimum_Quantity__c = 1,
            Maximum_Quantity__c = 100000,
            CurrencyIsoCode = 'USD',
            Sync_Currencies__c = true
        );

        insert mainCustomPricing;

        Test.startTest();

        mainCustomPricing.Base_Price__c = 18000;

        update mainCustomPricing;

        Test.stopTest();

        List<Custom_Pricing__c> customPricingResults = [
            SELECT Id, Base_Price__c
            FROM Custom_Pricing__c
            WHERE
                Product__c = :productId
                AND Price_Book__c = :standardPricebookId
                AND CurrencyIsoCode != 'USD'
        ];

        System.assert(
            customPricingResults.size() > 0,
            'Custom Pricing records were not created for other currencies when expected'
        );
    }
}