@IsTest
public with sharing class BlockPriceCurrencyHandlerTest {
    static Set<String> requiredPermissionSets = new Set<String>{
        'Global_Read',
        'SteelBrickCPQUser'
    };

    @TestSetup
    static void setupData() {
        TestUserProvisioner provisioner = new TestUserProvisioner(
            UserInfo.getUserId()
        );
        provisioner.setLicenses(
            new List<String>{
                'SalesforceCPQ_CPQStandardPerm'
            }
        );
        provisioner.setPermissions(
            new List<String>{
                'Global_Read',
                'CPQ_Global',
                'SteelBrickCPQUser'
            }
        );
        provisioner.assignPermissions();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Product2 testProd = new Product2(
                Name = 'Test Product Block Price',
                ProductCode = 'TST-PRD-BLOCK-PRICE'
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
                ),
                new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = testProd.Id,
                    UnitPrice = 1500,
                    CurrencyIsoCode = 'EUR',
                    IsActive = true
                )
            };
        }
    }

    @IsTest
    public static void testInsertBlockPriceSync() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Block Price'
        ]
        .Id;

        Id standardPricebookId = Test.getStandardPricebookId();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();

            insert new SBQQ__BlockPrice__c(
                Name = 'Tier 1',
                Sync_Currencies__c = true,
                CurrencyIsoCode = 'USD',
                SBQQ__LowerBound__c = 1,
                SBQQ__UpperBound__c = 100000,
                SBQQ__Price__c = 1000,
                SBQQ__PriceBook2__c = standardPricebookId,
                SBQQ__Product__c = productId
            );

            Test.stopTest();
        }

        List<SBQQ__BlockPrice__c> results = [
            SELECT Id
            FROM SBQQ__BlockPrice__c
            WHERE
                SBQQ__Product__c = :productId
                AND SBQQ__PriceBook2__c = :standardPricebookId
                AND CurrencyIsoCode != 'USD'
        ];

        System.assert(
            results.size() > 0,
            'Block prices were not created when the sync box was checked'
        );
    }

    @IsTest
    public static void testInsertBlockPriceNoSync() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Block Price'
        ]
        .Id;

        Id standardPricebookId = Test.getStandardPricebookId();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();

            insert new SBQQ__BlockPrice__c(
                Name = 'Tier 1',
                Sync_Currencies__c = false,
                CurrencyIsoCode = 'USD',
                SBQQ__LowerBound__c = 1,
                SBQQ__UpperBound__c = 100000,
                SBQQ__Price__c = 1000,
                SBQQ__PriceBook2__c = standardPricebookId,
                SBQQ__Product__c = productId
            );

            Test.stopTest();
        }

        List<SBQQ__BlockPrice__c> results = [
            SELECT Id
            FROM SBQQ__BlockPrice__c
            WHERE
                SBQQ__Product__c = :productId
                AND SBQQ__PriceBook2__c = :standardPricebookId
                AND CurrencyIsoCode != 'USD'
        ];

        System.assert(
            results.size() == 0,
            'Block prices were created when the sync box was not checked'
        );
    }

    @IsTest
    public static void testUpdateBlockPriceSync() {
        Id productId = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product Block Price'
        ]
        .Id;

        Id standardPricebookId = Test.getStandardPricebookId();

        SBQQ__BlockPrice__c baseBP = new SBQQ__BlockPrice__c(
            Name = 'Tier 1',
            Sync_Currencies__c = false,
            CurrencyIsoCode = 'USD',
            SBQQ__LowerBound__c = 1,
            SBQQ__UpperBound__c = 100000,
            SBQQ__Price__c = 1000,
            SBQQ__PriceBook2__c = standardPricebookId,
            SBQQ__Product__c = productId
        );

        SBQQ__BlockPrice__c baseBPGBP = new SBQQ__BlockPrice__c(
            Name = 'Tier 1',
            Sync_Currencies__c = false,
            CurrencyIsoCode = 'GBP',
            SBQQ__LowerBound__c = 1,
            SBQQ__UpperBound__c = 100000,
            SBQQ__Price__c = 1000,
            SBQQ__PriceBook2__c = standardPricebookId,
            SBQQ__Product__c = productId
        );

        insert new List<SBQQ__BlockPrice__c> {baseBP, baseBPGBP};

        List<SBQQ__BlockPrice__c> results = [
            SELECT Id
            FROM SBQQ__BlockPrice__c
            WHERE
                SBQQ__Product__c = :productId
                AND SBQQ__PriceBook2__c = :standardPricebookId
                AND CurrencyIsoCode != 'USD'
        ];

        System.assert(
            results.size() == 1,
            'Block prices were created when the sync box was not checked'
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();

            baseBp.Sync_Currencies__c = true;
            update baseBP;

            Test.stopTest();
        }

        results = [
            SELECT Id
            FROM SBQQ__BlockPrice__c
            WHERE
                SBQQ__Product__c = :productId
                AND SBQQ__PriceBook2__c = :standardPricebookId
                AND CurrencyIsoCode != 'USD'
        ];

        System.assert(
            results.size() > 1,
            'Block prices were not created when the sync box was checked'
        );
    }
}