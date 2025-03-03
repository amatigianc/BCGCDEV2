@IsTest
public with sharing class SubscriptionCustomAmendHandlerTest {
    @TestSetup
    static void setupData() {
        Product2 customProd = new Product2(
            Name = 'Custom Amend Product',
            ProductCode = 'CUSTOM-PRODUCT',
            Custom_Amend__c = true
        );

        Product2 regularProd = new Product2(
            Name = 'Regular Amend Product',
            ProductCode = 'STANDARD-PRODUCT',
            Custom_Amend__c = false
        );

        insert new List<Product2>{ customProd, regularProd };

        Id standardPricebookId = Test.getStandardPricebookId();

        insert new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = customProd.Id,
                UnitPrice = 100,
                CurrencyIsoCode = 'USD',
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = regularProd.Id,
                UnitPrice = 100,
                CurrencyIsoCode = 'USD',
                IsActive = true
            )
        };
    }

    @IsTest
    public static void testNonCustomProduct() {
        Product2 standardProduct = [
            SELECT Id
            FROM Product2
            WHERE ProductCode = 'STANDARD-PRODUCT'
        ];

        SBQQ__Subscription__c originalSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = standardProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 100,
            SBQQ__SpecialPrice__c = 100,
            SBQQ__CustomerPrice__c = 80,
            SBQQ__RegularPrice__c = 100,
            SBQQ__NetPrice__c = 80,
            SBQQ__RenewalPrice__c = 80
        );

        insert originalSubscription;

        SBQQ__Subscription__c revisedSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = standardProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 200,
            SBQQ__SpecialPrice__c = 200,
            SBQQ__CustomerPrice__c = 180,
            SBQQ__RegularPrice__c = 200,
            SBQQ__NetPrice__c = 180,
            SBQQ__RenewalPrice__c = 180,
            SBQQ__RevisedSubscription__c = originalSubscription.Id
        );

        Test.startTest();

        insert revisedSubscription;

        Test.stopTest();

        revisedSubscription = [
            SELECT Id
            FROM SBQQ__Subscription__c
            WHERE Id = :revisedSubscription.Id
        ];

        System.assert(
            revisedSubscription != null,
            'Revised Subscription doesn\'t exist'
        );
    }

    @IsTest
    public static void testCustomProduct() {
        Product2 customProduct = [
            SELECT Id
            FROM Product2
            WHERE ProductCode = 'CUSTOM-PRODUCT'
        ];

        SBQQ__Subscription__c originalSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = customProduct.Id,
            SBQQ__Quantity__c = 1,
            Number_of_Plays__c = 100,
            SBQQ__ProrateMultiplier__c = 1.0,
            SBQQ__ListPrice__c = 100,
            SBQQ__SpecialPrice__c = 100,
            SBQQ__CustomerPrice__c = 80,
            SBQQ__RegularPrice__c = 100,
            SBQQ__NetPrice__c = 80,
            SBQQ__RenewalPrice__c = 80
        );

        insert originalSubscription;

        SBQQ__Subscription__c revisedSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = customProduct.Id,
            SBQQ__Quantity__c = 1,
            Number_of_Plays__c = 200,
            SBQQ__ProrateMultiplier__c = 0.75,
            SBQQ__ListPrice__c = 200,
            SBQQ__SpecialPrice__c = 200,
            SBQQ__CustomerPrice__c = 180,
            SBQQ__RegularPrice__c = 200,
            SBQQ__NetPrice__c = 180,
            SBQQ__RenewalPrice__c = 180,
            SBQQ__RevisedSubscription__c = originalSubscription.Id
        );

        Test.startTest();

        insert revisedSubscription;

        Test.stopTest();

        List<SBQQ__Subscription__c> revisedSubscriptions = [
            SELECT Id
            FROM SBQQ__Subscription__c
            WHERE Id = :revisedSubscription.Id
        ];

        System.assert(
            revisedSubscriptions.IsEmpty(),
            'Subscription records were not removed.'
        );

        originalSubscription = [
            SELECT Id, Number_of_Plays__c
            FROM SBQQ__Subscription__c
            WHERE Id = :originalSubscription.Id
        ];

        System.assertEquals(
            200,
            originalSubscription.Number_of_Plays__c,
            'New list price not updated correctly'
        );
    }

    @IsTest
    public static void testCustomProductDiscountAmount() {
        Product2 customProduct = [
            SELECT Id
            FROM Product2
            WHERE ProductCode = 'CUSTOM-PRODUCT'
        ];

        SBQQ__Subscription__c originalSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = customProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ProrateMultiplier__c = 1.0,
            SBQQ__AdditionalDiscountAmount__c = 20,
            SBQQ__ListPrice__c = 100,
            SBQQ__SpecialPrice__c = 100,
            SBQQ__CustomerPrice__c = 80,
            SBQQ__RegularPrice__c = 100,
            SBQQ__NetPrice__c = 80,
            SBQQ__RenewalPrice__c = 80
        );

        insert originalSubscription;

        SBQQ__Subscription__c revisedSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = customProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ProrateMultiplier__c = 0.75,
            SBQQ__AdditionalDiscountAmount__c = 20,
            SBQQ__ListPrice__c = 150,
            SBQQ__SpecialPrice__c = 150,
            SBQQ__CustomerPrice__c = 135,
            SBQQ__RegularPrice__c = 150,
            SBQQ__NetPrice__c = 135,
            SBQQ__RenewalPrice__c = 135,
            SBQQ__RevisedSubscription__c = originalSubscription.Id
        );

        Test.startTest();

        insert revisedSubscription;

        Test.stopTest();

        List<SBQQ__Subscription__c> revisedSubscriptions = [
            SELECT Id
            FROM SBQQ__Subscription__c
            WHERE Id = :revisedSubscription.Id
        ];

        System.assert(
            revisedSubscriptions.IsEmpty(),
            'Subscription records were not removed.'
        );

        originalSubscription = [
            SELECT Id, SBQQ__ListPrice__c, SBQQ__NetPrice__c
            FROM SBQQ__Subscription__c
            WHERE Id = :originalSubscription.Id
        ];

        //maths!
        System.assertEquals(
            200,
            originalSubscription.SBQQ__ListPrice__c,
            'New list price not updated correctly'
        );
        System.assertEquals(
            180,
            originalSubscription.SBQQ__NetPrice__c,
            'New net price not updated correctly'
        );
    }

    @IsTest
    public static void testCustomProductDiscountPercent() {
        Product2 customProduct = [
            SELECT Id
            FROM Product2
            WHERE ProductCode = 'CUSTOM-PRODUCT'
        ];

        SBQQ__Subscription__c originalSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = customProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ProrateMultiplier__c = 1.0,
            SBQQ__Discount__c = 20,
            SBQQ__ListPrice__c = 100,
            SBQQ__SpecialPrice__c = 100,
            SBQQ__CustomerPrice__c = 80,
            SBQQ__RegularPrice__c = 100,
            SBQQ__NetPrice__c = 80,
            SBQQ__RenewalPrice__c = 80
        );

        insert originalSubscription;

        SBQQ__Subscription__c revisedSubscription = new SBQQ__Subscription__c(
            SBQQ__Product__c = customProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ProrateMultiplier__c = 0.75,
            SBQQ__Discount__c = 20,
            SBQQ__ListPrice__c = 150,
            SBQQ__SpecialPrice__c = 150,
            SBQQ__CustomerPrice__c = 120,
            SBQQ__RegularPrice__c = 150,
            SBQQ__NetPrice__c = 120,
            SBQQ__RenewalPrice__c = 120,
            SBQQ__RevisedSubscription__c = originalSubscription.Id
        );

        Test.startTest();

        insert revisedSubscription;

        Test.stopTest();

        List<SBQQ__Subscription__c> revisedSubscriptions = [
            SELECT Id
            FROM SBQQ__Subscription__c
            WHERE Id = :revisedSubscription.Id
        ];

        System.assert(
            revisedSubscriptions.IsEmpty(),
            'Subscription records were not removed.'
        );

        originalSubscription = [
            SELECT Id, SBQQ__ListPrice__c, SBQQ__NetPrice__c
            FROM SBQQ__Subscription__c
            WHERE Id = :originalSubscription.Id
        ];

        //maths!
        System.assertEquals(
            200,
            originalSubscription.SBQQ__ListPrice__c,
            'New list price not updated correctly'
        );
        System.assertEquals(
            160,
            originalSubscription.SBQQ__NetPrice__c,
            'New net price not updated correctly'
        );
    }
}