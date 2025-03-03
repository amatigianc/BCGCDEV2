@IsTest
public with sharing class PricebookManagerControllerTest {
    @TestSetup
    static void setupData() {
        Product2 testProd = new Product2(
            Name = 'Test Product Pricebook Manager',
            ProductCode = 'TST-PRD-PRCE-MNGR'
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
    public static void testGetUSDPricebookEntry() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Pricebook Manager'
        ]
        .Id;
        List<PricebookEntry> usdPricebookEntries = PricebookManagerController.getUSDPricebookEntry(
            productId
        );
        System.assert(
            usdPricebookEntries.size() == 1,
            'Did not get expected number of USD pricebook entries'
        );
    }

    @IsTest
    public static void testToggleActivation() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Pricebook Manager'
        ]
        .Id;
        PricebookEntry pbe = [
            SELECT Id, IsActive, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE
                Product2Id = :productId
                AND Pricebook2Id = :Test.getStandardPricebookId()
                AND CurrencyIsoCode = 'USD'
        ];
        System.assert(pbe.IsActive == true, 'Pricebook Entry should be true');
        PricebookManagerController.toggleActivation(pbe);
        pbe = [SELECT Id, IsActive FROM PricebookEntry WHERE Id = :pbe.Id];
        System.assert(pbe.IsActive == false, 'Pricebook Entry should be false');
    }

    @IsTest
    public static void testDeletePricebookEntry() {
        Boolean recordsExist = true;
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Pricebook Manager'
        ]
        .Id;
        PricebookEntry pbe = [
            SELECT Id, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE
                Product2Id = :productId
                AND Pricebook2Id = :Test.getStandardPricebookId()
                AND CurrencyIsoCode = 'USD'
        ];
        PricebookManagerController.deletePricebookEntry(pbe);
        try {
            pbe = [SELECT Id, IsActive FROM PricebookEntry WHERE Id = :pbe.Id];
        } catch (System.QueryException e) {
            recordsExist = false;
        }
        System.assert(
            recordsExist == false,
            'Pricebook Entry shouldn\'t exist'
        );
    }

    @IsTest
    public static void testCreateUpdatePricebookEntries() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Pricebook Manager'
        ]
        .Id;
        PricebookEntry pbe = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice
            FROM PricebookEntry
            WHERE
                Product2Id = :productId
                AND Pricebook2Id = :Test.getStandardPricebookId()
                AND CurrencyIsoCode = 'USD'
        ];
        PricebookManagerController.createUpdatePricebookEntries(
            pbe.Product2Id,
            pbe.Pricebook2Id,
            pbe.UnitPrice
        );
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, UnitPrice
            FROM PricebookEntry
            WHERE
                Product2Id = :pbe.Product2Id
                AND Pricebook2Id = :pbe.Pricebook2Id
                AND CurrencyIsoCode != 'USD'
        ];
        System.assert(
            pricebookEntries.size() > 1,
            'Newly Created pricebook entries do not exist'
        );
    }

    @IsTest
    public static void testExceptions() {
        Boolean getUSDPricebookThrown = false;
        Boolean toggleActivationThrown = false;
        Boolean deletePricebookThrown = false;
        Boolean createUpdatePricebookThrown = false;
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Pricebook Manager'
        ]
        .Id;
        PricebookEntry pbe = [
            SELECT Id
            FROM PricebookEntry
            WHERE
                Product2Id = :productId
                AND Pricebook2Id = :Test.getStandardPricebookId()
                AND CurrencyIsoCode = 'USD'
        ];

        try {
            PricebookManagerController.getUSDPricebookEntry(null);
        } catch (Exception e) {
            getUSDPricebookThrown = true;
        }

        try {
            PricebookManagerController.toggleActivation(pbe);
        } catch (Exception e) {
            toggleActivationThrown = true;
        }

        try {
            PricebookManagerController.deletePricebookEntry(pbe);
        } catch (Exception e) {
            deletePricebookThrown = true;
        }

        try {
            PricebookManagerController.createUpdatePricebookEntries(
                '123456',
                '123456',
                10
            );
        } catch (Exception e) {
            createUpdatePricebookThrown = true;
        }

        System.assert(
            getUSDPricebookThrown == true,
            'getUSDPricebookEntry did not throw an exception'
        );
        System.assert(
            toggleActivationThrown == true,
            'toggleActivation did not throw an exception'
        );
        System.assert(
            deletePricebookThrown == true,
            'deletePricebookEntry did not throw an exception'
        );
        System.assert(
            createUpdatePricebookThrown == true,
            'createUpdatePricebookEntries did not throw an exception'
        );
    }
}