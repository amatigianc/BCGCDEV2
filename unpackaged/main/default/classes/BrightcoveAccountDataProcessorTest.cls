@isTest(isparallel=true)
public with sharing class BrightcoveAccountDataProcessorTest {
    @isTest
    static void testPut() {
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(getRequestJson());
        RestContext.request = request;
        RestContext.response = new RestResponse();
        DataService.doPut();

        RestResponse response = RestContext.response;

        String responseBody = String.valueOf(response.responseBody);
        Integer responseCode = response.statusCode;

        System.assertNotEquals(null, responseBody, 'Response was null.');

        List<Brightcove_Account__c> brightAccounts = [
            SELECT Id, GUID__c
            FROM Brightcove_Account__c
            LIMIT 1
        ];
        System.assertEquals(
            1,
            brightAccounts.size(),
            'Incorrect number of records created.'
        );
    }

    @isTest
    static void testInvalidProcessor() {
        RestRequest request = new RestRequest();
        Map<String, Object> requestMap = new Map<String, Object>{
            'requestName' => 'Bad Request Name',
            'data' => getDataMap()
        };
        request.requestBody = Blob.valueOf(JSON.serialize(requestMap));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        DataService.doPut();

        RestResponse response = RestContext.response;

        String responseBody = response.responseBody.toString();
        Integer responseCode = response.statusCode;

        System.assertNotEquals(null, responseBody, 'Response was null.');

        Map<String, Object> responseObjMap = (Map<String, Object>) JSON.deserializeUntyped(
            responseBody
        );

        System.assertEquals(
            false,
            (Boolean) responseObjMap.get('success'),
            'Invocation was successful'
        );

        System.assertEquals(
            'Invalid Request',
            (String) responseObjMap.get('message'),
            'Incorrect message returned.'
        );
    }

    @isTest
    static void testException() {
        RestRequest request = new RestRequest();
        Map<String, Object> requestMap = new Map<String, Object>{
            'requestName' => 'CreateBrightcoveAccounts',
            'data' => 'bad data'
        };
        request.requestBody = Blob.valueOf(JSON.serialize(requestMap));
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        DataService.doPut();
        Test.stopTest();

        RestResponse response = RestContext.response;

        System.assertEquals(null, response.responseBody, 'Response was null.');
    }

    static String getRequestJson() {
        Map<String, Object> requestMap = new Map<String, Object>{
            'requestName' => 'CreateBrightcoveAccounts',
            'data' => getDataMap()
        };

        return JSON.serialize(requestMap);
    }

    static Object getDataMap() {
        Map<String, SObjectField> fields = Brightcove_Account__c.getSObjectType()
            .getDescribe(SObjectDescribeOptions.DEFERRED)
            .fields.getMap();

        return new List<Map<String, Object>>{
            new Map<String, Object>{
                'primaryAccountOwnerEmail' => 'BrightcoveAccountDataProcessorTest@example.com',
                'max_users' => 10,
                'account_profile' => fields.get('Account_Profile__c')
                        .getDescribe()
                        .getPicklistValues()[0]
                    .getValue(),
                'Publisher_Status__c' => fields.get('Publisher_Status__c')
                        .getDescribe()
                        .getPicklistValues()[0]
                    .getValue(),
                'tier' => fields.get('Tier__c')
                        .getDescribe()
                        .getPicklistValues()[0]
                    .getValue(),
                'bcAccountId' => 'BrightcoveAccountDataProcess',
                'Billing_Account_Expiration_Date__c' => '2023-05-05'
            }
        };
    }
}